import 'package:flutter/material.dart';
import 'package:mobile_project/login/login.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  
  // TODO: Add your user list data here
  final List<Map<String, String>> dummyUsers = [
    {'email': 'user1@example.com'},
    {'email': 'user2@example.com'},
    {'email': 'user3@example.com'},
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea
    (
      child:Scaffold
      (
        backgroundColor: const Color.fromRGBO(37, 39, 62, 1),
        appBar: AppBar

        (
          backgroundColor: const Color.fromRGBO(37, 39, 62, 1),
          automaticallyImplyLeading: false,
          title: const Align
          (
            alignment: Alignment.center,
            
            child: Text('homepage',style: TextStyle(fontSize: 45,color:  Colors.white,fontWeight: FontWeight.bold))
          ),
          toolbarHeight: 130,
          titleSpacing: 20,
          actions: 
          [
            IconButton(
              color: Colors.white,
              icon: const Icon(Icons.logout,size: 30),
              onPressed: (){
                // Navigate back to login page
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const login()),
                );
              },
            )
          ],
        ),
        body: _userlist(),
        
      ) 
    );
  }
  
  Widget _userlist(){
    return ListView.builder(
      itemCount: dummyUsers.length,
      itemBuilder: (context, index) {
        return _listitem(dummyUsers[index]);
      },
    );
  }
  
  Widget _listitem(Map<String, String> userData)
  {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color.fromARGB(255, 219, 99, 90),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        title: Row(
          children: [
            const Icon(Icons.person,color: Colors.white,size: 30,weight:10 ),
            const SizedBox(width: 10,),
            Text(
              userData['email'] ?? 'Unknown',
              style: const TextStyle(fontSize: 25,color: Colors.white,fontWeight: FontWeight.bold),
            ),
          ],
        ),
        onTap: ()
        {
          // TODO: Add navigation to chat page here
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Chat with ${userData['email']}'),
            ),
          );
        },
      ),
    );
  }
}