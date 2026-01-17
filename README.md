# CNN Implementation on Pytorch and SystemVerilog # 


## MNIST Learning using Pytorch ##

**Neural Network Architecture**
<img width="1102" height="520" alt="image" src="https://github.com/user-attachments/assets/5d41df6c-4de0-4d94-b257-01683e638eab" />


The network has one convolution layer and one fully connected layer. The hyperparameters are below:

* Batch Size = 64

* Training Epoch = 10

* Learning Rate = 0.01

* Optimizer = Stochastical Gradient Descent (Momentum = 0.5)

* Activation Function = ReLU
  


<br>
<br>
<br>
<br>
<br>


## System Verilog Design ##

**Block Diagram**

<img width="1278" height="547" alt="image" src="https://github.com/user-attachments/assets/72e82ddd-4028-45c7-9e4a-d9ecc3dffba7" />

**Simulation waveform and output**

<img width="1021" height="312" alt="image" src="https://github.com/user-attachments/assets/bb8316ee-56bd-4376-a9cc-1f6cc97f1752" />


<img width="939" height="535" alt="image" src="https://github.com/user-attachments/assets/9c3b1219-dfbe-40e3-97f0-dbd6acd5b696" />


<br>
<br>
<br>
<br>
<br>

**Sample Resource Utilization with Using Lattice Avant E70** 

<img width="809" height="495" alt="image" src="https://github.com/user-attachments/assets/ef979a1f-4747-4383-90a3-b8de41225e84" />
<img width="886" height="537" alt="image" src="https://github.com/user-attachments/assets/fa513715-d880-4282-be7f-3f064d480887" />

<br>
<br>
<br>
<br>
<br>


Some notes:

* This design is not tested on hardware and is implemented on goal of learning machine learning accelerators
* This design could be optimized further and is not timing closed 
