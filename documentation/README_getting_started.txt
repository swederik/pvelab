Matlab must have a path to the PipelineProgram directory, but not to the PipelineProgram's subfolders.

There are 3 pipeline programs: PVElab - marslab - examplelab. 


How it works:
For an easy start we have made the examplelab pipeline. Run it by typing examplelab.
 
examplelab.m uses setupexamplelab.ini to setup the pipeline. The examplelab is intended to demonstrate how easy it is to setup a pipeline.
In the PipelineProgram\example\ directory the 2 basic files exist:
	example_wrapper.m to demonstrate how a method is implemented 
	exampleConfig_wrapper.m to demonstrate how a method is configured  
By modifying these 2 files you should be able to implement your method and configurator. 



* For more details see PipelineProgram\documentation\PipelineProgramDescription.pdf *

* Bugs can be reported to michael@nru.dk *

