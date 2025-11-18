/****************************************************************************** 
 * TRNG end-to-end timing test
 *  - PL (top_trng) cung cấp:
 *      + data_out[31:0]   -> axi_gpio_0 (PS đọc)
 *      + start            -> axi_gpio_1 (PS đọc)
 *      + button (pop)     <- axi_gpio_2 (PS ghi)
 *  - PS (Zynq) sẽ:
 *      + Chờ start = 1
 *      + Pop 350 lần: phát xung button, đọc data_out, printf UART
 *      + Đo thời gian bằng Cortex-A9 private timer (SCU timer)
 ******************************************************************************/

#include "platform.h"
#include "xparameters.h"
#include "xil_types.h"
#include "xgpio.h"
#include "xscutimer_hw.h"   // truy cập thanh ghi SCU timer trực tiếp
#include <stdio.h>

#define NUM_SAMPLES      350

/* Địa chỉ base của Cortex-A9 private timer trên Zynq */
#define SCUTIMER_BASEADDR   0xF8F00600U

/* Theo datasheet: private timer chạy ở Fcpu/2.
 * BSP của bạn cũng dùng công thức này trong xtimer_config.h.
 */
#define TIMER_FREQ_HZ   (XPAR_CPU_CORE_CLOCK_FREQ_HZ/2U)

/* Khởi tạo timer: free-running, đếm xuống 32-bit, auto-reload */
static void MyTimer_Init(void)
{
    /* Tắt timer, clear control (bao gồm cả prescaler) */
    XScuTimer_SetControlReg(SCUTIMER_BASEADDR, 0x00000000U);

    /* Nạp giá trị max, khi chạy sẽ đếm xuống rồi tự nạp lại */
    XScuTimer_SetLoadReg(SCUTIMER_BASEADDR, 0xFFFFFFFFU);

    /* Bật auto-reload + enable, prescaler = 0 */
    XScuTimer_SetControlReg(
        SCUTIMER_BASEADDR,
        XSCUTIMER_CONTROL_ENABLE_MASK |       /* bit 0: enable */
        XSCUTIMER_CONTROL_AUTO_RELOAD_MASK    /* bit 1: auto-reload */
        /* prescaler bits đã = 0 */
    );
}

/* Đọc giá trị counter hiện tại (32-bit, đếm xuống) */
static inline u32 MyTimer_GetCounter(void)
{
    return XScuTimer_GetCounterReg(SCUTIMER_BASEADDR);
}

int main(void)
{
    init_platform();

    /******************** GPIO 0: data_out[31:0] từ PL ********************/
    XGpio gpio_data;
    XGpio_Config cfg_data = {0};
    cfg_data.BaseAddress = XPAR_XGPIO_0_BASEADDR;      // axi_gpio_0: data_out
    XGpio_CfgInitialize(&gpio_data, &cfg_data, cfg_data.BaseAddress);
    XGpio_SetDataDirection(&gpio_data, 1, 0xFFFFFFFFu); // all bits input

    /******************** GPIO 1: start từ PL *****************************/
    XGpio gpio_start;
    XGpio_Config cfg_start = {0};
    cfg_start.BaseAddress = XPAR_XGPIO_1_BASEADDR;     // axi_gpio_1: start
    XGpio_CfgInitialize(&gpio_start, &cfg_start, cfg_start.BaseAddress);
    XGpio_SetDataDirection(&gpio_start, 1, 0xFFFFFFFFu); // input

    /******************** GPIO 2: button (PS -> PL) ***********************/
    XGpio gpio_button;
    XGpio_Config cfg_button = {0};
    cfg_button.BaseAddress = XPAR_XGPIO_2_BASEADDR;    // axi_gpio_2: button
    XGpio_CfgInitialize(&gpio_button, &cfg_button, cfg_button.BaseAddress);
    XGpio_SetDataDirection(&gpio_button, 1, 0x00000000u); // output

    /* đảm bảo button = 0 ban đầu */
    XGpio_DiscreteWrite(&gpio_button, 1, 0u);

    /* Khởi tạo private timer */
    MyTimer_Init();
    printf("Private timer initialized. TIMER_FREQ_HZ = %lu Hz\r\n",
           (unsigned long)TIMER_FREQ_HZ);

    printf("TRNG end-to-end test (TRNG -> PS -> UART)\r\n");
    printf("GPIO mapping:\r\n");
    printf("  axi_gpio_0 -> data_out[31:0] (input)\r\n");
    printf("  axi_gpio_1 -> start (input)\r\n");
    printf("  axi_gpio_2 -> button (output)\r\n");
    printf("Waiting for start signal from PL (axi_gpio_1 bit 0)...\r\n");

    while (1) {
        /*************** 1) Chờ start từ PL lên 1 *************************/
        u32 s;
        do {
            s = XGpio_DiscreteRead(&gpio_start, 1) & 0x1u;
        } while (s == 0u);

        printf("\r\n=== START detected, capturing %d samples ===\r\n",
               NUM_SAMPLES);

        /*************** 2) Đọc giá trị timer lúc bắt đầu ******************/
        u32 t_start = MyTimer_GetCounter();

        for (unsigned int i = 0; i < NUM_SAMPLES; ++i) {
            /* Phát 1 xung button: 0 -> 1 -> 0 (mỗi xung pop 1 word) */
            XGpio_DiscreteWrite(&gpio_button, 1, 1u);
            XGpio_DiscreteWrite(&gpio_button, 1, 0u);

            /* Đọc data_out ngay sau xung */
            u32 v = XGpio_DiscreteRead(&gpio_data, 1);

            /* In ra UART (tính luôn thời gian UART) */
            printf("%03u: %08lX\r\n", i + 1, (unsigned long)v);
        }

        /*************** 3) Đọc timer lúc kết thúc *************************/
        u32 t_end = MyTimer_GetCounter();

        /* Timer đếm xuống 32-bit, diff = số tick đã trôi qua.
           Giả sử thời gian đo < ~13 giây nên không bị overflow. */
        u32 ticks = t_start - t_end;

        double seconds = (double)ticks / (double)TIMER_FREQ_HZ;
        unsigned long long us =
            (unsigned long long)(seconds * 1000000.0);

        printf("========================================\r\n");
        printf("Total samples : %d\r\n", NUM_SAMPLES);
        printf("t_start       : 0x%08lX\r\n", (unsigned long)t_start);
        printf("t_end         : 0x%08lX\r\n", (unsigned long)t_end);
        printf("Total ticks   : %lu\r\n", (unsigned long)ticks);
        printf("Total time    : %llu microseconds\r\n", us);
        printf("Total time    : %.6f seconds\r\n", seconds);
        printf("Average/sample: %.3f microseconds per sample\r\n",
               (double)us / (double)NUM_SAMPLES);
        printf("========================================\r\n");

        /*************** 4) Chờ start về 0 rồi mới cho phép run lại ****** */
        printf("Waiting for start to go LOW...\r\n");
        do {
            s = XGpio_DiscreteRead(&gpio_start, 1) & 0x1u;
        } while (s != 0u);
        printf("Start LOW detected, ready for next run.\r\n");
    }

    cleanup_platform();
    return 0;
}
