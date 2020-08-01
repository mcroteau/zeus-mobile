import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:zeus/authenticate.dart';
import 'package:zeus/base.dart';
import 'package:http/http.dart' as http;
import 'package:zeus/common/c.dart';
import 'package:zeus/components/zeus_header.dart';
import 'package:zeus/components/zeus_highlight.dart';
import 'package:zeus/services/navigation_service.dart';
import 'dart:convert';

import 'components/searchbox.dart';

class Profile extends StatefulWidget{
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends BaseState<Profile>{

  _ProfileState({Key key, @required this.id});

  var radius = 70.0;
  var topHeight = 170.0;

  var id;
  var session;

  dynamic profile;
  var friends = [];

  var requestSent = false;

  NavigationService navigationService;

  @override
  void initState(){
    super.initState();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    this.id = GetStorage().read(C.ID);
    this.session = GetStorage().read(C.SESSION);
    print("profile id : " + this.id.toString());
    print("profile session : " + this.session.toString());
    return Scaffold(
      body: new FutureBuilder(
        future: _fetch(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data['profile'] != null) {
            return new Container(
                child: new Stack(
                  alignment: Alignment.topCenter,
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.fromLTRB(0, 110, 0, 0),
                      child: new CircleAvatar(
                          radius: radius,
                          backgroundImage: NetworkImage(C.API_URI + snapshot.data['profile']['imageUri'])
                      ),
                    ),
                    Container(
                        padding: EdgeInsets.fromLTRB(0, 270, 0, 0),
                        child: Column(
                          children: [
                            Text(snapshot.data['profile']['name'], style: TextStyle(color: Colors.black, fontSize: 27, fontWeight: FontWeight.w700, decoration: TextDecoration.none, fontFamily: "Roboto")),
                            Container(
                              child: Text(snapshot.data['profile']['location'] != null ? snapshot.data['profile']['location'] : "", style: TextStyle(color: Colors.black, fontSize: 14, decoration: TextDecoration.none))
                            ),

                            if(snapshot.data['profile']['isFriend'])
                              Container(
                                  child: Text("Friends")
                              ),

                            if(!snapshot.data['profile']['isFriend'] && !snapshot.data['profile']['isOwnersAccount'])
                              Container(
                                child:  RaisedButton(
                                    child: Text("Send Buddy Request"),
                                    elevation: 3,
                                    color: Colors.yellow,
                                    textColor: Colors.black,
                                    onPressed: !requestSent ? () => _sendReq(snapshot.data['profile']['id'].toString()) : null
                                )
                              ),

                            if(snapshot.data['friends'].length > 0)
                              Container(
                                padding: EdgeInsets.fromLTRB(30, 20, 0, 0),
                                alignment: Alignment.centerLeft,
                                child:Text("Friends", textAlign: TextAlign.left, style: TextStyle(fontSize:14, fontWeight: FontWeight.normal, color: Colors.black26, fontFamily:"Roboto", decoration: TextDecoration.none))
                              ),

                            Expanded(
                              child: ListView(
                                children: <Widget>[
                                  for(var friend in snapshot.data['friends'])
                                    Row(
                                    children: <Widget>[
                                      Container(
                                        padding: EdgeInsets.fromLTRB(30, 10, 0, 0),
                                        child: GestureDetector(
                                          onTap: (){
                                            _storeProfileId(friend['friendId'].toString()).then((data){
                                              navigationService.navigateTo('/profile');
                                            });
                                          },
                                          child: CircleAvatar(
                                            radius: 20,
                                            backgroundImage: NetworkImage(C.API_URI + friend['imageUri']),
                                          ),
                                        ),
                                      ),
                                      Container(
                                          padding: EdgeInsets.fromLTRB(40, 10, 0, 0),
                                          child: GestureDetector(
                                            onTap: (){
                                              _storeProfileId(friend['friendId'].toString()).then((data){
                                                navigationService.navigateTo('/profile');
                                              });

                                            },
                                            child: Text(friend['name'], style: TextStyle(fontSize: 17, fontWeight: FontWeight.normal, fontFamily: "Roboto", decoration: TextDecoration.none)),
                                        )
                                      )
                                    ],
                                  )
                              ],
                            ),
                            ),
                          ]
                        ),
                    ),
                    Positioned(
                      top:0,
                      left:0,
                      right: 0,
                      child : ZeusHeader(),
                    ),
                    Positioned(
                      bottom:0,
                      left:0,
                      right: 0,
                      child: ZeusHighlight(),
                    ),
                  ],

                ),
              color: Colors.white,
            );
          } else if(snapshot.hasError)
            return Text("$snapshot.error");
          else
            return new Center(child: CircularProgressIndicator());
        }
      )
    );
  }

  Future _storeProfileId(id){
    GetStorage().write(C.ID, id);
  }

  Future<dynamic> _fetch() async {
    http.Response profileData = await http.get(
        C.API_URI + "profile/" + this.id.toString(),
        headers : {
          "content-type": "application/json",
          "accept": "application/json",
          "cookie" : this.session
        }
    );

    var data = jsonDecode(profileData.body.toString());
    profile = data['profile'];
    friends = data['friends'];

    if(data['error'] != null){
      navigationService.navigateTo('/authenticate');
    }

    return data;
  }

  Future<dynamic> _sendReq(id) async {
    super.showGlobalDialog("Sending...", null);
    http.Response req = await http.post(
        C.API_URI + "friend/invite/" + id,
        headers: {
          "content-type": "application/json",
          "accept": "application/json",
          "cookie": this.session
        }
    );

    print(req.body.toString());
    var data = jsonDecode(req.body.toString());

    if(data['success']){
      super.showGlobalDialog("Successfully sent buddy request.", null);
    }else{
      super.showGlobalDialog("Whoa, apologies, there was an issue, please try again...", null);
      requestSent = true;
      return null;
    }

  }
}