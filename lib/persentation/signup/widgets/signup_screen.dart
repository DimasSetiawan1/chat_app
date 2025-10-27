import 'package:chat_apps/persentation/signup/controller/signup_controller.dart';
import 'package:chat_apps/sharing/component/widgets/custom_dropdown_item.dart';
import 'package:chat_apps/sharing/component/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SignupScreen extends StatelessWidget {
  SignupScreen({super.key});

  final authController = Get.find<SignupController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) {
          final fullNameController = TextEditingController();
          final emailController = TextEditingController();
          final passwordController = TextEditingController();
          final confirmPasswordController = TextEditingController();
          final GlobalKey<FormState> formKey = GlobalKey<FormState>();
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      const FlutterLogo(size: 72),
                      const SizedBox(height: 12),
                      const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // import 'package:image_picker/image_picker.dart';
                      // import 'dart:io';

                      // Obx(
                      //   () => GestureDetector(
                      //     onTap: () async {
                      //       final picker = ImagePicker();
                      //       final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                      //       if (pickedFile != null) {
                      //         authController.selectedImage.value = File(pickedFile.path);
                      //       }
                      //     },
                      //     child: Container(
                      //       height: 100,
                      //       width: 100,
                      //       decoration: BoxDecoration(
                      //         color: Colors.grey[200],
                      //         borderRadius: BorderRadius.circular(12),
                      //         image: authController.selectedImage.value != null
                      //             ? DecorationImage(
                      //                 image: FileImage(authController.selectedImage.value!),
                      //                 fit: BoxFit.cover,
                      //               )
                      //             : null,
                      //       ),
                      //       child: authController.selectedImage.value == null
                      //           ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                      //           : null,
                      //     ),
                      //   ),
                      // ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: fullNameController,
                        labelText: "Full name",
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Role',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.person_outline),
                          filled: true,
                          fillColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                        ),
                        isExpanded: true,
                        items: [
                          customDropdownItem(
                            context: context,
                            title: 'Student',
                            value: 'student',
                            icon: Icons.school_outlined,
                          ),
                          customDropdownItem(
                            context: context,
                            title: 'Tutor',
                            value: 'tutor',
                            icon: Icons.record_voice_over_outlined,
                          ),
                          customDropdownItem(
                            context: context,
                            title: 'Parent',
                            value: 'parent',
                            icon: Icons.family_restroom,
                          ),
                        ],
                        onChanged: (value) {
                          authController.role.value = value ?? 'student';
                        },
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: emailController,
                        labelText: "Email",
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: passwordController,
                        labelText: "Password",
                        isPassword: true,
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: confirmPasswordController,
                        labelText: "Confirmation Password",
                        isPassword: true,
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              final email = emailController.text.trim();
                              final fullName = fullNameController.text.trim();
                              final password = passwordController.text.trim();
                              final confirm = confirmPasswordController.text
                                  .trim();
                              if (email.isEmpty ||
                                  password.isEmpty ||
                                  fullName.isEmpty ||
                                  confirm.isEmpty) {
                                Get.snackbar(
                                  'Error',
                                  'Please fill in all fields',
                                );
                                return;
                              }

                              if (password != confirm) {
                                Get.snackbar(
                                  'Warning',
                                  'Confirmation password does not match',
                                );
                                return;
                              }

                              await authController.signUpWithEmailAndPassword(
                                fullName,
                                email,
                                password,
                              );
                            }
                          },
                          child: Obx(
                            () => authController.isLoading.value
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Sign Up'),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Already have an account?'),
                          TextButton(
                            onPressed: () {
                              Get.toNamed('/');
                            },
                            child: const Text('Login'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
