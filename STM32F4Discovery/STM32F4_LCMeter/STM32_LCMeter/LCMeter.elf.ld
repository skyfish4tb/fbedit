
/*
!!! Primary linker script file generated automatically !!!
This file contains the input and output files names
It also includes the secondary/main linker script that is specified in the Ride options (default or custom)
*/

SEARCH_DIR(".")
SEARCH_DIR("D:\FbEdit\Projects\Applications\fbe\STM32F4Discovery\STM32F4_LCMeter\STM32_LCMeter")
SEARCH_DIR("D:\Ride\Ride\Lib\ARM")
STARTUP(".\startup_stm32f4xx.o")
INPUT("D:\FbEdit\Projects\Applications\fbe\STM32F4Discovery\STM32F4_LCMeter\STM32_LCMeter\main.o")
INPUT("D:\FbEdit\Projects\Applications\fbe\STM32F4Discovery\STM32F4_LCMeter\STM32_LCMeter\stm32f4xx_it.o")
INPUT("D:\FbEdit\Projects\Applications\fbe\STM32F4Discovery\STM32F4_LCMeter\STM32_LCMeter\stm32f4xx_rcc.o")
INPUT("D:\FbEdit\Projects\Applications\fbe\STM32F4Discovery\STM32F4_LCMeter\STM32_LCMeter\stm32f4xx_gpio.o")
INPUT("D:\FbEdit\Projects\Applications\fbe\STM32F4Discovery\STM32F4_LCMeter\STM32_LCMeter\stm32f4xx_tim.o")
INPUT("D:\FbEdit\Projects\Applications\fbe\STM32F4Discovery\STM32F4_LCMeter\STM32_LCMeter\misc.o")
INPUT("D:\FbEdit\Projects\Applications\fbe\STM32F4Discovery\STM32F4_LCMeter\STM32_LCMeter\system_stm32f4xx.o")
INPUT("D:\FbEdit\Projects\Applications\fbe\STM32F4Discovery\STM32F4_LCMeter\STM32_LCMeter\stm32f4_discovery.o")
INPUT("D:\FbEdit\Projects\Applications\fbe\STM32F4Discovery\STM32F4_LCMeter\STM32_LCMeter\stm32f4xx_dac.o")
INPUT("D:\FbEdit\Projects\Applications\fbe\STM32F4Discovery\STM32F4_LCMeter\STM32_LCMeter\stm32f4xx_spi.o")
INPUT("D:\FbEdit\Projects\Applications\fbe\STM32F4Discovery\STM32F4_LCMeter\STM32_LCMeter\stm32f4xx_usart.o")
INPUT("D:\FbEdit\Projects\Applications\fbe\STM32F4Discovery\STM32F4_LCMeter\STM32_LCMeter\stm32f4xx_adc.o")
INPUT("D:\FbEdit\Projects\Applications\fbe\STM32F4Discovery\STM32F4_LCMeter\STM32_LCMeter\stm32f4xx_dma.o")
EXTERN( __io_putchar )
EXTERN( _write )
GROUP(
"STM32x_io_putchar_thumb.a"
"std_sbrk_thumb.lib"
"smallprintf_thumb.a"
"libc.a"
"libm.a"

)
INCLUDE "D:\FbEdit\Projects\Applications\fbe\STM32F4Discovery\STM32F4_LCMeter\STM32_LCMeter\STM32F100_64K_8K_FLASH.ld"
OUTPUT("D:\FbEdit\Projects\Applications\fbe\STM32F4Discovery\STM32F4_LCMeter\STM32_LCMeter\LCMeter.elf")
