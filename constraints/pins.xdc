#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets reset_N]

set_property IOSTANDARD LVCMOS18 [get_ports dht11_data_0]
set_property IOSTANDARD LVCMOS18 [get_ports led_fan_0]
set_property IOSTANDARD LVCMOS18 [get_ports led_hum_0]
set_property IOSTANDARD LVCMOS18 [get_ports led_mod_0]
set_property IOSTANDARD LVCMOS18 [get_ports tx_0]
set_property IOSTANDARD LVCMOS18 [get_ports rx_0]
set_property IOSTANDARD LVCMOS18 [get_ports rst_n_0]
set_property IOSTANDARD LVCMOS18 [get_ports scl_lcd_0]
set_property IOSTANDARD LVCMOS18 [get_ports sda_lcd_0]

set_property PACKAGE_PIN A8 [get_ports rst_n_0]
set_property PACKAGE_PIN D7 [get_ports rx_0]
set_property PACKAGE_PIN D6 [get_ports tx_0]
set_property PACKAGE_PIN F7 [get_ports sda_lcd_0]
set_property PACKAGE_PIN F8 [get_ports scl_lcd_0]
set_property PACKAGE_PIN F4 [get_ports led_fan_0]
set_property PACKAGE_PIN B6 [get_ports led_hum_0]
set_property PACKAGE_PIN D8 [get_ports led_mod_0]
set_property PACKAGE_PIN E5 [get_ports dht11_data_0]








set_property IOSTANDARD LVCMOS18 [get_ports led1_test_0]
set_property IOSTANDARD LVCMOS18 [get_ports led2_test_0]
set_property PACKAGE_PIN B4 [get_ports led1_test_0]
set_property PACKAGE_PIN A7 [get_ports led2_test_0]
