# StackLang - Obfuscation by Virtualization
StackLang is a small x86 MASM assembly project that demonstrates obstructing an algorithm by using virtualization. A custom virtual machine / interpreter is embedded into the application. The embedded virtual machine interprets an algorithm written in bytecode.

The virtualized algorithm computes a hash of the input data and compares it to the expected hash value. If the hashes match, a message informing you that you have entered the correct password is displayed.

#### Purpose
The purpose of this application is to provide a basic example of how virtualization can be used to obfuscate code or more specifically an algorithm. With this project, I hope to do further research and development into automatic identification of bytecode in an obfuscated application.

#### License

Licensed under MIT License.