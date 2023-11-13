
import 'dart:convert';
import 'dart:developer';
import 'dart:math'as math;

import 'package:bcall/Components/Drawer%20Components/CustomDrawer.dart';
import 'package:bcall/Components/Drawer%20Components/LeftPageDrawer.dart';
import 'package:bcall/Components/Drawer%20Components/MainPageDrawer.dart';
import 'package:bcall/Components/PlaceholderContainer.dart';
import 'package:bcall/Providers/UserProvider.dart';
import 'package:bcall/Screens/VideoCallScreen.dart';
import 'package:bcall/Style/colors_style.dart';
import 'package:bcall/Style/text_style.dart';
import 'package:bcall/services/SignallingService.dart';
import 'package:flutter/material.dart';
import 'package:iconify_flutter/icons/ph.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/fluent_emoji_high_contrast.dart';
import 'package:overlapping_panels/overlapping_panels.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String websocketUrl = "http://10.0.2.2:5001/";
  //final String websocketUrl = "http://localhost:5001/";
  //final String selfCallerId = math.Random().nextInt(999999).toString().padLeft(6, '0');
  
  dynamic incomingSDPOffer;
  TextEditingController remoteCallerIdController = TextEditingController();

  final List<Widget> _children = [
    PlaceholderWidget('Friends'),
    PlaceholderWidget('Video')
  ];

  String username = 'DNS';
  String id = 'DNS';
  List<dynamic> friends = [];
  String selfCallerId = '000000';

  Future<void> _getUser() async {
    log('Masuk ke log getUser()');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';

    final response = await UserProvider().getUser(token);

    Map<String, dynamic> responseBody = json.decode(response.body);
    setState((){
      log(responseBody.toString());
      username = responseBody['username'];
      id = responseBody['_id'];
      friends = responseBody['friends'];
      selfCallerId = id.substring(id.length - 6);
      log('Hasil Response $id $username $friends');
    });
  }


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    log("My caller ID: ${selfCallerId}");
    _getUser();
    
  }

  _joinCall({
    required String callerId,
    required String calleeId,
    dynamic offer,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          callerId: callerId,
          calleeId: calleeId,
          offer: offer,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SignallingService.instance.init(
      websocketUrl: websocketUrl,
      selfCallerID: selfCallerId
    );

    SignallingService.instance.socket!.on("newCall", (data) {
      log(incomingSDPOffer.toString());
      if (mounted) {
        // set SDP Offer of incoming call
        setState(() => incomingSDPOffer = data);
      }
    });

    return Scaffold(
      backgroundColor: secondary2,
      appBar: AppBar(
        backgroundColor: secondary2,
        title: Text('${username} ${selfCallerId}', style: title,),
        actions: [
          IconButton(
            icon: const Iconify(Ph.video_camera_fill, color: Colors.white,), // widget,
            onPressed: () {
              _joinCall(
                callerId: selfCallerId,
                calleeId: '232322323',
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              children: [
                TextField(
                  controller: remoteCallerIdController,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: "Remote Caller ID",
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0)
                    )
                  ),
                ),
                const SizedBox(height: 12,),
                ElevatedButton(
                  child: const Text("Invite"),
                  onPressed: (){
                    _joinCall(callerId: selfCallerId, calleeId: remoteCallerIdController.text);
                  },
                )
              ],
            ),
          ),
          incomingSDPOffer != null 
          ? Positioned(
              child: Column(
                  children: [
                    Text("Incoming Call from ${incomingSDPOffer["callerId"]}"),
                    IconButton(
                      icon: const Icon(Icons.call_end),
                      color: Colors.redAccent,
                      onPressed: (){
                        setState(() {
                          incomingSDPOffer = null;
                        });
                      },
                    ),
                    IconButton(
                        icon: const Icon(Icons.call),
                        color: Colors.greenAccent,
                        onPressed: () {
                          _joinCall(
                            callerId: incomingSDPOffer["callerId"]!,
                            calleeId: selfCallerId,
                            offer: incomingSDPOffer["sdpOffer"],
                          );
                        },
                      )
                  ],
                ),
              )
            
          : Container()
          
        ],
      ),
      drawer: CustomDrawer(friendList: friends,),

    );
    // return Stack(
    //   children: [
    //     OverlappingPanels(
    //       left: Builder(
    //         builder: (context) => const LeftPage(),
    //       ),
    //       main: Builder(
    //         builder: (context) => const MainPage(),
    //       )
    //     )
    //   ],
    // );

    
  }
}