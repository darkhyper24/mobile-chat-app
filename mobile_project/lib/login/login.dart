import 'package:flutter/material.dart';
import 'package:mobile_project/signup/signup.dart';
import 'package:mobile_project/home/home.dart';
class login extends StatefulWidget {
  const login({super.key});

  @override
  State<login> createState() => _loginState();
}
class _loginState extends State<login> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isShown = true;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
              backgroundColor: const Color.fromRGBO(37, 39, 62, 1),
              appBar: AppBar(
                automaticallyImplyLeading: false,
                title: const Align(
                  alignment: Alignment.bottomLeft,
                  child: Text("Login"),
                ),
                toolbarHeight: 220,
                titleSpacing: 30,
                titleTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 45,
                  fontWeight: FontWeight.bold,
                ),
                backgroundColor: const Color.fromRGBO(37, 39, 62, 1),
              ),
              body: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: emailController,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return "This value can't be empty";
                            }
                            return null;
                          },
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color.fromARGB(255, 219, 99, 90),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color.fromARGB(255, 219, 99, 90),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color.fromARGB(255, 219, 99, 90),
                              ),
                            ),
                            hintText: "Email",
                            hintStyle: const TextStyle(
                              color: Colors.grey,
                              fontSize: 18,
                            ),
                            prefixIcon: const Icon(
                              Icons.person,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(height: 35),
                        TextFormField(
                          controller: passwordController,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return "This value can't be empty";
                            }
                            return null;
                          },
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                          obscureText: isShown,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color.fromARGB(255, 219, 99, 90),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color.fromARGB(255, 219, 99, 90),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color.fromARGB(255, 219, 99, 90),
                              ),
                            ),
                            hintText: "Password",
                            hintStyle: const TextStyle(
                              color: Colors.grey,
                              fontSize: 18,
                            ),
                            prefixIcon: const Icon(
                              Icons.lock,
                              color: Colors.grey,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  isShown = !isShown;
                                });
                              },
                              icon: Icon(
                                isShown ? Icons.visibility : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        MaterialButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              // Navigate to homepage
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const Homepage()),
                              );
                            }
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          height: 50,
                          minWidth: 450,
                          color: const Color.fromARGB(255, 219, 99, 90),
                          child: const Text(
                            "Login",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 100),
                        const Text(
                          "Or Sign in with",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 25),
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 65,
                                height: 70,
                                child: TextButton(
                                  onPressed: () {},
                                  child: Image.network(
                                    "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b9/2023_Facebook_icon.svg/1024px-2023_Facebook_icon.svg.png",
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 65,
                                height: 70,
                                child: TextButton(
                                  onPressed: () {},
                                  child: Image.network(
                                    "https://cdn-icons-png.freepik.com/256/5969/5969020.png?semt=ais_hybrid",
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 65,
                                height: 70,
                                child: TextButton(
                                  onPressed: () {},
                                  child: Image.network(
                                    "https://www.citypng.com/public/uploads/preview/round-circle-g-plus-google-icon-701751695133225k60gamywzo.png",
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 65,
                                height: 70,
                                child: TextButton(
                                  onPressed: () {},
                                  child: Image.network(
                                    "https://cdn-icons-png.flaticon.com/512/1384/1384063.png",
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "Don't have an account?",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  // TODO: Navigate to signup page
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => signup(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Sign Up",
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 139, 58, 58),
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
  }
}
