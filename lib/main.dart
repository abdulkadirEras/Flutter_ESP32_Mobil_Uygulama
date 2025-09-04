
import 'package:flutter/material.dart';
import 'AnaSayfa.dart';
import 'package:flutter_animated_splash/flutter_animated_splash.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';


void main() {


  runApp( MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(appBarTheme: const AppBarTheme(shadowColor: Colors.red)),
        debugShowMaterialGrid: false,
        debugShowCheckedModeBanner: false,
        title: 'Temas Controller',
        darkTheme: ThemeData.light(),

        home: AnimatedSplash(
          durationInSeconds: 2,
          curve: Curves.linear,

          navigator: const AnaSayfa(),
          type: Transition.leftToRightWithFade,



          backgroundColor: Colors.indigo, child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("TEMAS",style: TextStyle(color: Colors.white,fontSize: 40,fontFamily: 'Myfont'),),
              const SizedBox(height: 64,),
              LoadingAnimationWidget.dotsTriangle(
                color: Colors.white,
                size: 40,
              ),
              const Text("Yükleniyor",style: TextStyle(color: Colors.white,fontSize: 16,fontFamily: 'Myfont'),)

            ],
          ),
        ),
    );
  }
}



/*
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TemasController',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AnaSayfa(),
    );
  }
}

*/