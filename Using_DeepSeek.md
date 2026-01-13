# DEEPSEEK

Running DeepSeek Models Locally with Ollama and Chatbox AI

This guide will walk you through the steps to download, install, and run DeepSeek models on your local machine using Ollama and Chatbox AI. By following these instructions, you can enjoy offline access to powerful AI models.

### Prerequisites

  * A Linux-based operating system (Ubuntu, Debian, etc.)
  * Basic familiarity with the command line
  * Stable internet connection for downloading software and models

## Step 1: Install Ollama

Ollama is a tool that allows you to easily download and run AI models locally. To install Ollama, follow these steps:

  Open your terminal.
  Run the following command to download and install Ollama:
  
  ```
  curl -fsSL https://ollama.com/install.sh | sh
  ```
  ![ollama-download](https://github.com/user-attachments/assets/42a9c889-b08f-40a3-880b-e4ea544215d5)

  This script will automatically download and install Ollama on your system.

## Step 2: Download DeepSeek Models

Ollama supports various DeepSeek models. You can choose the model that best suits your needs. Below are the commands to download different DeepSeek models:

  DeepSeek-R1-Distill-Qwen-1.5B (1.5 billion parameters):
  ```
  ollama run deepseek-r1:1.5b
  ```
  DeepSeek-R1-Distill-Qwen-7B (7 billion parameters):
  ```
    ollama run deepseek-r1:7b
  ```
  DeepSeek-R1-Distill-Llama-8B (8 billion parameters):
  ```
    ollama run deepseek-r1:8b
  ```
  DeepSeek-R1-Distill-Qwen-14B (14 billion parameters):
  ```
    ollama run deepseek-r1:14b
  ```

  DeepSeek-R1-Distill-Qwen-32B (32 billion parameters):
  ```
    ollama run deepseek-r1:32b
  ```
  DeepSeek-R1-Distill-Llama-70B (70 billion parameters):
  ```
    ollama run deepseek-r1:70b
  ```
![ollama-install_](https://github.com/user-attachments/assets/677e29bd-e182-48b8-9d46-55648b0d3446)

Choose the model you want to use and run the corresponding command. Ollama will download and set up the model for you.

## Step 3: Install Chatbox AI

Chatbox AI is a user-friendly interface that allows you to interact with the DeepSeek models you’ve downloaded. Follow these steps to install Chatbox AI:

  1. Download Chatbox AI for Linux [download](https://chatboxai.app/en/install?download=linux)

  2. Once the download is complete, navigate to the directory where the AppImage is located.

  3. Make the AppImage executable by running the following command:
     
    chmod +x Chatbox-1.9.5-x86_64.AppImage

  5. Run Chatbox AI by executing the following command:
     
    ./Chatbox-1.9.5-x86_64.AppImage
    
## Step 4: Configure Chatbox AI to Use Ollama

After launching Chatbox AI, you need to configure it to use the Ollama provider and the DeepSeek model you downloaded:

  1. Open Chatbox AI.

  2. Go to Settings.

  3. Under Model Provider, select Ollama AI.
![ollama](https://github.com/user-attachments/assets/ab360e26-8266-4f16-a790-6b2e26c03146)

  4. In the Model dropdown, select the DeepSeek model you downloaded (e.g., deepseek-r1:1.5b).
![ollama1](https://github.com/user-attachments/assets/0229f76b-70c4-4b61-84d7-6157351b3751)

  5. Click Save to apply the changes.

## Step 5: Enjoy Running DeepSeek Locally

You’re all set! You can now interact with the DeepSeek model directly from Chatbox AI, running locally. Enjoy exploring the capabilities of your chosen DeepSeek model.
Troubleshooting

  Model Not Loading: Ensure that Ollama is running and the model has been successfully downloaded. You can check the status of Ollama by running ollama list in the terminal.

  Chatbox AI Not Launching: Make sure the AppImage is executable and that your system supports AppImages. You may need to install additional dependencies if you encounter issues.

## Conclusion

By following this guide, you’ve successfully set up DeepSeek models on your local machine using Ollama and Chatbox AI. This setup allows you to leverage powerful AI models locally, providing you with a seamless and private AI experience.

Note: This guide is intended for Linux users. If you are using a different operating system, please refer to the official documentation for platform-specific instructions.
