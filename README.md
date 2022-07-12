# CAN-dropout-error-counter
This matlab script counts the number of dropouts, the number of errors, and gets the total runtime of every MF4 CAN log in a specified folder. It prints the results to a text file in a separate folder.

To use this, run the counter.m file and give it a directory with MF4s. The other two .m files are functions that are required for the counter script to work, so make sure that they are in the same directory as the counter.m file. The output log is located in the new folder as dropouts_and_errors.txt

This will not overwrite the original MF4 files. It makes a new directory and copies the files over, then makes modifications to the copied files.

A dropout is defined as a deviation of greater than 5ms from the modal time between messages.
