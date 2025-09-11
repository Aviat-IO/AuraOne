

### **Objective:**

To create a multi-modal, on-device AI pipeline in Flutter that processes location history, movement data, and photos to generate a daily summary. The following steps are designed to be executed sequentially.

---

### **Step 1: Project Setup and Core Dependencies**

1. **Initialize Flutter Project:** Create a new Flutter application for Android and iOS.  
2. **Add Dependencies:** Open pubspec.yaml and add the primary package for on-device model inference:  
   * tflite\_flutter: Provides Dart bindings for the TensorFlow Lite native library, enabling high-performance, on-device ML.1  
3. **Configure Native Projects:** Follow the tflite\_flutter documentation to set up the native build files 1:  
   * **Android:** Modify build.gradle to include the TensorFlow Lite library.  
   * **iOS:** Update the Podfile and ensure the minimum deployment target is compatible. For release builds, adjust the "Strip Style" setting in Xcode to "Non-Global Symbols" to prevent symbol stripping errors.1  
4. **Asset Management:** Create an assets folder in the root of your Flutter project. All TensorFlow Lite models (.tflite files) will be stored here. Declare this folder in pubspec.yaml.

---

### **Step 2: Spatiotemporal Data Processing**

This stage converts raw sensor data into structured events.

#### **2.1 Location Clustering (Identifying "Stay Points")**

* **Goal:** Process a time-series of GPS coordinates to identify significant locations where the user spent time.  
* **Algorithm:** **DBSCAN** (Density-Based Spatial Clustering of Applications with Noise). This algorithm is ideal as it does not require a predefined number of clusters and can identify arbitrarily shaped clusters and noise (which represent travel paths).4  
* **Flutter Implementation:**  
  1. **Data Collection:** Use a Flutter plugin like location to gather background GPS data (latitude, longitude, timestamp).  
  2. **DBSCAN Logic:** Implement the DBSCAN algorithm in Dart. There are no mainstream, heavily maintained DBSCAN packages in the Flutter ecosystem, so this will likely require a custom implementation based on the algorithm's principles.4  
  3. **Parameters:**  
     * eps: A distance in meters that defines the radius of a neighborhood. This determines the size of a "place."  
     * MinPts: The minimum number of GPS points within the eps radius to define a core point. This translates to the minimum time spent at a location to be considered significant.  
  4. **Output:** A list of GPS points, each labeled with a cluster ID (a significant place) or as noise (a journey).

#### **2.2 Human Activity Recognition (HAR)**

* **Goal:** Classify the user's physical activity (e.g., stationary, walking, running) using IMU data (accelerometer, gyroscope).  
* **Model:** A pre-trained, lightweight **CNN-LSTM** model, optimized for time-series classification.5  
* **Flutter Implementation:**  
  1. **Obtain Model:** Find or train a HAR model and convert it to the TensorFlow Lite (.tflite) format. Apply post-training quantization to reduce its size to kilobytes.6  
  2. **Load Model:** Place the har\_model.tflite file in your assets folder. Load it in your app using tflite\_flutter 1:  
     Dart  
     import 'package:tflite\_flutter/tflite\_flutter.dart';  
     final interpreter \= await Interpreter.fromAsset('assets/har\_model.tflite');

  3. **Data Collection:** Use a plugin like sensors\_plus to get accelerometer and gyroscope data streams.  
  4. **Run Inference:**  
     * Preprocess the sensor data into the exact input tensor shape and type expected by the model (e.g., a fixed-length window of 3-axis readings).  
     * Run inference in a separate thread using IsolateInterpreter to avoid blocking the UI thread.1

  Dart  
       final isolateInterpreter \= await IsolateInterpreter.create(address: interpreter.address);  
       // \`input\` is the preprocessed sensor data  
       // \`output\` is a buffer to store the classification result  
       await isolateInterpreter.run(input, output);

  5. **Output:** A stream of activity labels (e.g., "Walking," "Stationary") with corresponding timestamps.

---

### **Step 3: Visual Context Extraction**

This stage extracts semantic meaning from photos taken by the user.

* **Goal:** Generate a descriptive sentence for each relevant photo.  
* **Model:** A pre-trained, lightweight image captioning model like **LightCap**, which is designed for on-device performance.7  
* **Flutter Implementation:**  
  1. **Obtain Model:** Acquire a quantized .tflite version of the LightCap model (or a similar efficient captioner) and add it to the assets folder.  
  2. **Load Model:** Use tflite\_flutter to load caption\_model.tflite.  
  3. **Image Access:** Use a plugin like photo\_manager or image\_picker to access photos from the user's gallery, filtering by the relevant day's timestamps.  
  4. **Run Inference:**  
     * For each image, preprocess it into the tensor format required by the model (e.g., resizing, normalizing pixel values).  
     * Use IsolateInterpreter to run the captioning model without freezing the UI.

  Dart  
       // \`image\_tensor\` is the preprocessed image  
       // \`caption\_output\` is a buffer for the generated text/tokens  
       await isolateInterpreter.run(image\_tensor, caption\_output);

  5. **Output:** A descriptive string (e.g., "A photo of a laptop on a wooden desk") for each processed image.  
* **Alternative (Simpler Prototyping):** For faster initial development, use the google\_ml\_kit\_image\_labeling or google\_mlkit\_object\_detection packages to get labels instead of full captions.2 This is less descriptive but easier to implement.

---

### **Step 4: Multi-modal Fusion and Event Correlation**

* **Goal:** Combine the outputs from Steps 2 and 3 into a single, chronologically ordered, and contextually aware data structure.  
* **Algorithm:** This is primarily a data structuring and logic step, followed by an optional advanced modeling step.  
* **Flutter Implementation:**  
  1. **Temporal Correlation:** Create a Dart function to build a unified timeline.  
     * Iterate through the day's timestamps.  
     * Use the DBSCAN output to segment the timeline into "Stay" and "Journey" events.  
     * For each event, associate the corresponding HAR labels from Step 2.2.  
     * For each "Stay" event, attach any image captions from Step 3 that were generated from photos taken during that time window.  
  2. **Data Structure:** Define a Dart class to hold the fused information:  
     Dart  
     class DailyEvent {  
       final EventType type; // Stay or Journey  
       final DateTime startTime;  
       final DateTime endTime;  
       final String? locationId; // From DBSCAN  
       final List\<String\> activities; // From HAR  
       final List\<String\> photoCaptions; // From Image Captioning  
     }

  3. **(Advanced) Transformer-Based Fusion:** To learn deeper context, a custom-trained Transformer encoder model can be used. This would take the structured DailyEvent data, convert it into numerical embeddings, and process it to output contextually enriched vectors. This is a significant ML task and would require an additional .tflite model deployed via tflite\_flutter.

---

### **Step 5: Narrative Generation**

* **Goal:** Convert the fused sequence of daily events into a human-readable paragraph.  
* **Model:** A Small Language Model (SLM) optimized for on-device use, such as **Microsoft Phi-3 Mini** or **TinyLlama**.11  
* **Flutter Implementation:**  
  1. **Obtain Model:** Download a 4-bit quantized .tflite version of the chosen SLM and add it to the assets folder.  
  2. **Load Model:** Use tflite\_flutter to load the SLM.  
  3. **Prompt Engineering:** Create a prompt string from the list of DailyEvent objects generated in Step 4\. The prompt should instruct the model to write a summary. Example:  
     "Based on the following events, write a short summary of the day:  
     \- 8:00 AM to 9:00 AM: Journey, Walking.  
     \- 9:00 AM to 12:30 PM: Stay at Location\_A, Stationary. Photos taken: 'A laptop on a desk'.  
     \- 12:30 PM to 1:30 PM: Stay at Location\_B, Stationary. Photos taken: 'A sandwich and a salad on a plate'.

..."\`\`\`4. Run Inference (Critically Important):\* MUST use IsolateInterpreter. Running an SLM on the main thread will crash the app.\* Tokenize the input prompt and feed it to the model.\* Decode the output tokens back into a string.5. Output: A final, narrative summary of the user's day.

---

### **Step 6: Final Optimizations for Production**

1. **Hardware Acceleration:** When creating the Interpreter, enable hardware delegates to offload computation from the CPU, improving speed and battery life.1  
   Dart  
   final options \= InterpreterOptions();  
   // For Android  
   if (Platform.isAndroid) {  
     options.addDelegate(NnApiDelegate());  
   }  
   // For iOS  
   if (Platform.isIOS) {  
     options.addDelegate(GpuDelegate());  
   }  
   final interpreter \= await Interpreter.fromAsset('model.tflite', options: options);

2. **Model Quantization:** Ensure all .tflite models used in the pipeline are quantized (4-bit or 8-bit integer) to minimize memory footprint and accelerate CPU inference.  
3. **Permissions:** Implement logic to request necessary user permissions for location access (always), motion sensors, and photo gallery access.

#### **Works cited**

1. tflite\_flutter | Flutter package \- Pub.dev, accessed September 11, 2025, [https://pub.dev/packages/tflite\_flutter](https://pub.dev/packages/tflite_flutter)  
2. AI Integration in Flutter: Smart App Development Tips, accessed September 11, 2025, [https://www.zealousys.com/blog/ai-integration-in-flutter/](https://www.zealousys.com/blog/ai-integration-in-flutter/)  
3. Integrating TensorFlow Lite with Flutter for Machine Learning \- InheritX Solutions, accessed September 11, 2025, [https://knowledgebase.inheritxdev.in/integrating-tensorflow-lite-with-flutter-for-machine-learning/](https://knowledgebase.inheritxdev.in/integrating-tensorflow-lite-with-flutter-for-machine-learning/)  
4. DBSCAN Clustering in ML \- Density based clustering \- GeeksforGeeks, accessed September 11, 2025, [https://www.geeksforgeeks.org/machine-learning/dbscan-clustering-in-ml-density-based-clustering/](https://www.geeksforgeeks.org/machine-learning/dbscan-clustering-in-ml-density-based-clustering/)  
5. Human Activity Recognition \- Using Deep Learning Model \- GeeksforGeeks, accessed September 11, 2025, [https://www.geeksforgeeks.org/deep-learning/human-activity-recognition-using-deep-learning-model/](https://www.geeksforgeeks.org/deep-learning/human-activity-recognition-using-deep-learning-model/)  
6. Design and optimization of a TensorFlow Lite deep learning neural network for human activity recognition on a smartphone | Request PDF \- ResearchGate, accessed September 11, 2025, [https://www.researchgate.net/publication/356941208\_Design\_and\_optimization\_of\_a\_TensorFlow\_Lite\_deep\_learning\_neural\_network\_for\_human\_activity\_recognition\_on\_a\_smartphone](https://www.researchgate.net/publication/356941208_Design_and_optimization_of_a_TensorFlow_Lite_deep_learning_neural_network_for_human_activity_recognition_on_a_smartphone)  
7. Efficient Image Captioning for Edge Devices, accessed September 11, 2025, [https://ojs.aaai.org/index.php/AAAI/article/view/25359/25131](https://ojs.aaai.org/index.php/AAAI/article/view/25359/25131)  
8. Efficient Image Captioning for Edge Devices \- ResearchGate, accessed September 11, 2025, [https://www.researchgate.net/publication/371931760\_Efficient\_Image\_Captioning\_for\_Edge\_Devices](https://www.researchgate.net/publication/371931760_Efficient_Image_Captioning_for_Edge_Devices)  
9. New AI "LightCap" Shrinks Image Captioning for Your Phone, Runs ..., accessed September 11, 2025, [https://hackernoon.com/new-ai-lightcap-shrinks-image-captioning-for-your-phone-runs-on-cpu](https://hackernoon.com/new-ai-lightcap-shrinks-image-captioning-for-your-phone-runs-on-cpu)  
10. Google's ML Kit for Flutter \- Dart API docs \- Pub.dev, accessed September 11, 2025, [https://pub.dev/documentation/google\_ml\_kit/latest/](https://pub.dev/documentation/google_ml_kit/latest/)  
11. TinyLlama Is An Open-Source Small Language Model \- Kore.ai Blog, accessed September 11, 2025, [https://blog.kore.ai/cobus-greyling/tinyllama-is-an-open-source-small-language-model](https://blog.kore.ai/cobus-greyling/tinyllama-is-an-open-source-small-language-model)  
12. Phi-3 Technical Report: A Highly Capable Language Model Locally ..., accessed September 11, 2025, [https://arxiv.org/abs/2404.14219](https://arxiv.org/abs/2404.14219)