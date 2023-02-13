# Picture overlay tag
Bash script for text overlay on graphics images using ImageMagick suite

Using dialog where installed (see e.g. 'apt info dialog') otherwise prompts for input as follows:

	Source: <path to graphics file or directory>
	Id Tag: <identification tag for the file>
	Coords: <location where created>
	Author: <copyright owner>
	Target: <path to target directory>

Input parameters are updated to 'ptag.dat' file with each run
Requires 'convert' from the ImageMagick suite
