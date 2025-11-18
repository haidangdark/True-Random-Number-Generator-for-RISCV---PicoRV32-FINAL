# 2025-11-14T08:00:50.931239300
import vitis

client = vitis.create_client()
client.set_workspace(path="trng_vitis_for_uart_timer_fix_2")

platform = client.get_component(name="platform")
status = platform.build()

comp = client.get_component(name="hello_world")
comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

vitis.dispose()

