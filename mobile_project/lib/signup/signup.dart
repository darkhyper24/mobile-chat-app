import 'package:flutter/material.dart';
import 'package:mobile_project/login/login.dart';
class signup extends StatefulWidget {
  const signup({super.key});

  @override
  State<signup> createState() => _signupState();
}

class _signupState extends State<signup> {
  TextEditingController namecontroller = TextEditingController();
  TextEditingController emailcontroller = TextEditingController();
  TextEditingController Passwordcontroller = TextEditingController();
  TextEditingController confirmPasswordcontroller = TextEditingController();


  final _formkey = GlobalKey<FormState>();
  bool issecure = true;
  bool csecure = true;
  bool? check = false;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
          
        
          child: Scaffold(
            backgroundColor: const Color.fromRGBO(37, 39, 62, 1),
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: const Align(
                  alignment: Alignment.bottomLeft, child: Text("signup")),
              titleTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 45,
                fontWeight: FontWeight.bold,
              ),
              toolbarHeight: 220,
              titleSpacing: 20,
              backgroundColor: const Color.fromRGBO(37, 39, 62, 1),
            ),
            body: SingleChildScrollView(
              child: Form(
                key: _formkey,
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: namecontroller,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "this field mustn't be empty";
                          }

                          return null;
                        },
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                  color: Color.fromARGB(255, 219, 99, 90))),
                          hintText: "Name",
                          hintStyle:
                              const TextStyle(color: Colors.grey, fontSize: 18),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                                color: Color.fromARGB(255, 219, 99, 90)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                                color: Color.fromARGB(255, 219, 99, 90)),
                          ),
                        ),
                        keyboardType: TextInputType.name,
                      ),
                      const SizedBox(
                        height: 25,
                      ),
                      TextFormField(
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "this field mustn't be empty";
                          }

                          return null;
                        },
                        controller: emailcontroller,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                    color: Color.fromARGB(255, 219, 99, 90))),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                  color: Color.fromARGB(255, 219, 99, 90)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                  color: Color.fromARGB(255, 219, 99, 90)),
                            ),
                            hintText: "Email",
                            hintStyle: const TextStyle(
                                color: Colors.grey, fontSize: 18)),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(
                        height: 25,
                      ),
                      TextFormField(
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "this field mustn't be empty";
                          }

                          return null;
                        },
                        controller: Passwordcontroller,
                        obscureText: issecure,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                    color: Color.fromARGB(255, 219, 99, 90))),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                  color: Color.fromARGB(255, 219, 99, 90)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                  color: Color.fromARGB(255, 219, 99, 90)),
                            ),
                            hintText: "Password",
                            hintStyle: const TextStyle(
                                color: Colors.grey, fontSize: 18),
                            suffixIcon: TextButton(
                                onPressed: () {
                                  setState(() {
                                    issecure = !issecure;
                                  });
                                },
                                child: const Text(
                                  "Show",
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 15),
                                ))),
                        keyboardType: TextInputType.visiblePassword,
                      ),
                      const SizedBox(
                        height: 25,
                      ),
                      TextFormField(
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "this field mustn't be empty";
                          }
                          if (Passwordcontroller.text != value) {
                            return "password doesn't match";
                          }

                          return null;
                        },
                        controller: confirmPasswordcontroller,
                        obscureText: csecure,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                    color: Color.fromARGB(255, 219, 99, 90))),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                  color: Color.fromARGB(255, 219, 99, 90)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                  color: Color.fromARGB(255, 219, 99, 90)),
                            ),
                            hintText: "Confirm Password",
                            hintStyle: const TextStyle(
                                color: Colors.grey, fontSize: 18),
                            suffixIcon: TextButton(
                                onPressed: () {
                                  setState(() {
                                    csecure = !csecure;
                                  });
                                },
                                child: const Text(
                                  "Show",
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 15),
                                ))),
                        keyboardType: TextInputType.visiblePassword,
                      ),
                      const SizedBox(
                        height: 25,
                      ),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                                value: check,
                                activeColor: Colors.grey,
                                onChanged: (newbool) {
                                  setState(() {
                                    check = newbool;
                                  });
                                }),
                            const Text(
                              "I Agree with",
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 18),
                            ),
                            TextButton(
                                onPressed: () {},
                                child: const Text(
                                  "Privacy",
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 139, 58, 58),
                                      fontSize: 18),
                                )),
                            const Text(
                              "and",
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 18),
                            ),
                            TextButton(
                                onPressed: () {},
                                child: const Text(
                                  "Policy",
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 139, 58, 58),
                                      fontSize: 18),
                                ))
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                      MaterialButton(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        minWidth: 450,
                        height: 50,
                        onPressed: () {
                          if (_formkey.currentState!.validate()) {
                            // TODO: Add your signup logic here
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Sign up successful!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        color: const Color.fromARGB(255, 139, 58, 58),
                        textColor: Colors.grey,
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(
                        height: 60,
                      ),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Already have an account?",
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 18),
                            ),
                            TextButton(
                                onPressed: () {
                                  // TODO: Navigate to login page
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => login()));
                                },
                                child: const Text(
                                  "Sign in",
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 139, 58, 58),
                                      fontSize: 18),
                                ))
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
  }
}
