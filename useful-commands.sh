"""Navigate into the Quartus Nios CLI Folder"""

cd /cygdrive/c/Users/Kunststoffe/Desktop/EEE2Rover-master/DE10_LITE_D8M_VIP_16/software/D8M_Camera_Test/

////////////////////////////////////////////////////////////////////////////////////

"""Start the Nios2 Command Shell"""

& '.\Nios II Command Shell.bat'

////////////////////////////////////////////////////////////////////////////////////

"""Download the generated software onto the Nios2 Processor that is running"""

nios2-download D8M_Camera_Test.elf -c 1 -g

////////////////////////////////////////////////////////////////////////////////////


"""Compiling a test-bench example command"""

iverilog -Wall -g 2012 -s eee_imgproc_tb -o eee_imgproc_tb.out PIXEL_PROC.v RGB_2_HSV.v STREAM_REG.v EEE_IMGPROC_TB.v EEE_IMGPROC.v
