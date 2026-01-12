# **Deep Learning Image Colorizer & Enhancer**

## **📌 Project Overview**

This project is a hybrid software application designed to automatically colorize black-and-white images using Deep Learning. It integrates a **Python-based neural network backend** with a **MATLAB-based Graphical User Interface (GUI)**.

Beyond basic colorization, the application features a suite of post-processing tools:

* **Contrast Enhancement**  
* **Edge Sharpening**  
* **Scientific False-Color Mapping**

The system demonstrates successful cross-language integration (MATLAB \+ Python) and the practical application of **Convolutional Neural Networks (CNNs)** in Digital Image Processing.

## **🏗 System Architecture**

The project leverages a **Hybrid Architecture**:

1. **Frontend (MATLAB App Designer):** Handles user interaction, image visualization, post-processing effects, and file management. It provides a robust environment for engineering-grade image analysis.  
2. **Backend (Python \+ OpenCV \+ PyTorch):** Handles the heavy-duty deep learning inference. Python is used for its extensive libraries in machine learning.  
3. **Communication Bridge:** MATLAB executes Python scripts via system commands, passing file paths as arguments to ensure seamless data transfer between the GUI and the AI model.

## **🧠 The Deep Learning Model**

### **Model Architecture**

The core colorization engine is based on the research paper **"Colorful Image Colorization"** by *Richard Zhang, Phillip Isola, and Alexei A. Efros (ECCV 2016\)*.

* **Type:** Convolutional Neural Network (CNN).  
* **Structure:** The network resembles a **VGG-style architecture** but utilizes **Dilated Convolutions** (atrous convolutions). This allows the model to maintain a larger receptive field—seeing more of the image context at once—without downsampling the spatial resolution too heavily.  
* **Layers:** The architecture consists of 22 convolutional layers organized into 8 blocks, followed by a Softmax distribution layer.

### **L\*a\*b Color Space Strategy**

Unlike RGB images, which mix Red, Green, and Blue, this model operates in the **CIE L\*a\*b color space**:

* **Input (L):** The Lightness channel (Grayscale intensity). This is the only input provided to the network.  
* **Output (ab):** The model predicts the 'a' (Green-Red) and 'b' (Blue-Yellow) channels.  
* **Combination:** The input 'L' is concatenated with the predicted 'ab' to reconstruct the final color image.

### **Training Methodology**

The model was trained on the **ImageNet dataset** (approx. 1.3 million images).

* **Challenge:** Standard regression training tends to produce desaturated, sepia-toned images.  
* **Solution:** The model uses **Class Rebalancing** and **Quantization** (313 discrete color bins) to force the prediction of vibrant colors rather than defaulting to gray.

## **✨ Key Features**

* **Automatic Colorization:** Supports .jpg, .jpeg, .png, .bmp formats.  
* **Edge Sharpener:** Recovers high-frequency texture details using Unsharp Masking (imsharpen).  
* **Contrast Enhancer:** Uses CLAHE (Contrast Limited Adaptive Histogram Equalization) on the Luminance channel to fix "washed out" predictions.  
* **Scientific Visualization:** Maps pixel intensity to scientific colormaps (Thermal/Hot, Scientific/Jet, Parula, Cool) for analysis.  
* **Robust I/O:** Smart loading and saving with dynamic timestamping to prevent caching errors.

## **⚙️ Installation & Setup**

### **1\. Set up the Python Environment**

Open your terminal/command prompt in the project folder:

\# Create a virtual environment  
python \-m venv venv

\# Activate it (Windows)  
venv\\Scripts\\activate

\# Activate it (Mac/Linux)  
source venv/bin/activate

\# Install dependencies  
pip install numpy opencv-python

### **2\. Configure MATLAB**

1. Open ColorizerApp.m in MATLAB.  
2. Scroll to the ProcessButtonPushed function (approx. line 130).  
3. Update the pythonExe path to match your virtual environment:

% Example for Mac  
pythonExe \= '/Users/yourname/Desktop/DIP/venv/bin/python';

% Example for Windows  
% pythonExe \= 'C:\\Users\\yourname\\Desktop\\DIP\\venv\\Scripts\\python.exe';

### **3\. Download Model Weights**

Due to GitHub file size limits, the pre-trained weights are not included.

1. Create a folder named model/ in the root directory.  
2. Download and place the following files inside:  
   * [colorization\_release\_v2.caffemodel](https://www.dropbox.com/s/dx0qvhhp5hbcx7z/colorization_release_v2.caffemodel?dl=1)  
   * colorization\_deploy\_v2.prototxt  
   * pts\_in\_hull.npy

## **🚀 How to Run**

1. Open MATLAB.  
2. Navigate the "Current Folder" to this project directory.  
3. In the Command Window, type:  
   app \= ColorizerApp

4. The GUI will launch:  
   * **Step 1:** Click **Load** to select a B\&W image.  
   * **Step 2:** Click **Execute Model** to run the Deep Learning model.  
   * **Step 3:** Use checkboxes to apply **Sharpening** or **Contrast**.  
   * **Step 4:** Click **Save** to export your final result.

## **📂 Project Structure**

DIP\_Project/  
├── ColorizerApp.m      \# Main MATLAB GUI source code  
├── backend.py          \# Python script for model inference  
├── model/              \# Folder containing AI weights (Download separately)  
│   ├── colorization\_release\_v2.caffemodel  
│   ├── colorization\_deploy\_v2.prototxt  
│   └── pts\_in\_hull.npy  
└── README.md           \# This documentation file

## **📜 References**

* **Model Architecture:** Zhang, R., Isola, P., & Efros, A. A. (2016). Colorful Image Colorization. ECCV.  
* **Original Website:** [https://richzhang.github.io/colorization/](https://richzhang.github.io/colorization/)