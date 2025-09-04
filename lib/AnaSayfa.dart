import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'dart:async';




class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  _AnaSayfa createState() => _AnaSayfa();
}

class _AnaSayfa extends State<AnaSayfa> {
  int _currIndex=0;
  int _currIndex2=0;
  String _cihazAdi = '';
  bool _cihazBagliMi = false;
  bool _baglaniyorMu = false;
  bool connected=false;
  bool tekSefer=false;

  //BAĞLANTI KURULACAK AĞIN SSID VE ŞİFRESİNİ BURADAN GİRİNİZ.
  final String _SSID = 'Temas-Controller-AP';
  final String _sifresi = '123456789';


  Future<void> requestDeviceConfigPermission() async {
    // "READ_DEVICE_CONFIG" gibi bir izin varsa denenebilir
    var status = await Permission.nearbyWifiDevices;
    if (status.isGranted) {
      // İzin verildi, özelliği okumayı deneyebilirsiniz
    } else if (status.isDenied) {
      // İzin reddedildi
    } else if (status.isPermanentlyDenied) {
      // İzin kalıcı olarak reddedildi, kullanıcıyı ayarlara yönlendirin
      openAppSettings();
    }
  }



  Future<void> _baglantiKurmaDialogu(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Kullanıcının dışarıya tıklayarak kapatmasını engeller
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CircularProgressIndicator(),
              Padding(
                padding: EdgeInsets.only(top: 20.0),
                child: Column(
                  children: [
                    Text("Bağlantı Kuruluyor...",style: TextStyle(color: Colors.indigo),),
                    SizedBox(height: 10.0),
                    Text("Ağ bağlantısı gerçekleşmez ise bağlantıyı Ayarlardan sizin kurmanız gerekmektedir.",style: TextStyle(color: Colors.orange),),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }



  Future<bool> _onWillPop(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uyarı',style: TextStyle(color: Colors.orange),),
        content: const Text('Uygulamadan çıkmak istediğinize emin misiniz?'),
        actions: <Widget>[
          TextButton(
            style: ButtonStyle(
                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                        side: const BorderSide(color: Colors.red,width: 2)
                    )
                )
            ),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hayır'),
          ),
          TextButton(
            style: ButtonStyle(
                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                        side: const BorderSide(color: Colors.green,width: 2)
                    )
                )
            ),
            onPressed: () => SystemNavigator.pop(),
            child: const Text('Evet'),
          ),
        ],
      ),
    ) ??
        false; // showDialog null döndürebilir.
  }

  Future<bool> WifiyeBaglan(String ssid, String password) async {
    try {
      bool wifiEnabled = await WiFiForIoTPlugin.isEnabled();
      if (!wifiEnabled) {
        if (kDebugMode) {
          print("Wifi etkin değil, Lütfen wifi'ı açın.");
        }
        setState(() {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return UyariMesaji(
                baslik: 'Uyarı',
                icerik: 'Wifi etkin değil, \rLütfen Wifi\'ı açın ve Bağlantı butonuna basın.',
                onaylaButonu: () {
                  //WifiyeBaglan(_SSID, _sifresi);
                  // Onaylama işlemi
                  Navigator.of(context).pop(); // Dialog'u kapat

                },
                iptalButonu: () {
                  // İptal işlemi
                  Navigator.of(context).pop(); // Dialog'u kapat
                },
              );
            },
          );
        });

        return false;
      }
      String? _bagliMiydi= await WiFiForIoTPlugin.getSSID();

      if(_bagliMiydi==null || _bagliMiydi!=_SSID ){
        if (kDebugMode) {
          print("Karta bağlı değil");
        }




        WiFiForIoTPlugin.forceWifiUsage(true);

        _baglantiKurmaDialogu(context);

        await WiFiForIoTPlugin.findAndConnect(ssid,password: password,withInternet: true).then((value){
         if(value==true) {
             print("bağlantı başarılı");

           }
         else{
           print("bağlantı başarısız");
         }
        }
        );

        //await WiFiForIoTPlugin.connect(ssid,password: password,withInternet: true);
        await Future.delayed(const Duration(seconds: 3),(){

          Navigator.of(context).pop();//bağlantı tamamlandıktan sonra alert dialogu kapat

        });

        WiFiForIoTPlugin.forceWifiUsage(false);
        _bagliMiydi= await WiFiForIoTPlugin.getSSID();
        if (connected && _bagliMiydi==_SSID) {

          if(_bagliMiydi==_SSID){
            tekSefer=true;
          }

          if (kDebugMode) {
            print("Wifi ağına başarıyla bağlandı: $ssid");

          }

          setState(() {
            _cihazAdi = ssid;
            _cihazBagliMi = true;
            _baglaniyorMu = false;
          });
          return true;
        } else {
          if (kDebugMode) {
            print("Wifi ağına bağlanılamadı: $ssid");
          }
          setState(() {
            _cihazAdi='';
            _cihazBagliMi = false;
            _baglaniyorMu = false;
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return UyariMesaji(
                  baslik: 'Uyarı',
                  icerik: '$ssid ağına bağlanılamadı. Tekrar bağlantı kurmak için Bağlantı butonuna basın.',
                  onaylaButonu: () {
                    //WifiyeBaglan(_SSID, _sifresi);
                    // Onaylama işlemi
                    Navigator.of(context).pop(); // Dialog'u kapat

                  },
                  iptalButonu: () {
                    // İptal işlemi
                    Navigator.of(context).pop(); // Dialog'u kapat
                  },
                );
              },
            );
          });
          return false;
        }
      }
      else{
        if (kDebugMode) {
          print("Zaten bir cihaza bağlı");
        }

        setState(() {
          _cihazAdi = ssid;
          _cihazBagliMi = true;
          _baglaniyorMu = false;
        });

        return true;
      }

    } catch (e) {
      if (kDebugMode) {
        print("Wifi bağlantısı sırasında bir hata oluştu: $e");
      }
      setState(() {
        _cihazAdi='';
        _cihazBagliMi = false;
        _baglaniyorMu = false;

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return UyariMesaji(
              baslik: 'Uyarı',
              icerik: 'Bağlantı esnasında hata oluştu. Cihaza tekrar bağlantı kurun.',
              onaylaButonu: () {
                //WifiyeBaglan(_SSID, _sifresi);
                // Onaylama işlemi
                Navigator.of(context).pop(); // Dialog'u kapat

              },
              iptalButonu: () {
                // İptal işlemi
                Navigator.of(context).pop(); // Dialog'u kapat
              },
            );
          },
        );
      });

      return false;
    }
  }


  Future<void> monitorYukariKomutGonderFonk(String message) async {
    setState(() {
    });
    try {
     final response = await http.put(
        Uri.parse('http://192.168.0.1/$message'),
        headers: {'Content-Type': 'text/html'},

      );
      log("this is the morse response: $response");

      if (response.statusCode == 200) {
        setState(() {
        });
      } else {
        setState(() {
        });
      }
    } catch (e) {
      log("", error: e, name: "hata");
      setState(() {


        showDialog(
          context: context,
          builder: (BuildContext context) {
            return UyariMesaji(
              baslik: 'Hata',
              icerik: 'Cihaza veri gönderilemedi.',
              onaylaButonu: () {
                // Onaylama işlemi
                Navigator.of(context).pop(); // Dialog'u kapat

              },
              iptalButonu: () {
                // İptal işlemi
                Navigator.of(context).pop(); // Dialog'u kapat
              },
            );
          },
        );
      });
    }
  }

  Future<void> monitorAltaKomutGonderFonk(String message) async {
    setState(() {
    });
    try {
      final response = await http.put(
        Uri.parse('http://192.168.0.1/$message'),
        headers: {'Content-Type': 'text/html'},
      );
      log("this is the morse response: $response");

      if (response.statusCode == 200) {
        setState(() {
        });
      } else {
        setState(() {
        });
      }
    } catch (e) {
      log("", error: e, name: "hata");
      setState(() {

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return UyariMesaji(
              baslik: 'Hata',
              icerik: 'Cihaza veri gönderilemedi',
              onaylaButonu: () {
                // Onaylama işlemi
                Navigator.of(context).pop(); // Dialog'u kapat

              },
              iptalButonu: () {
                // İptal işlemi
                Navigator.of(context).pop(); // Dialog'u kapat
              },
            );
          },
        );
      });
    }
  }



  @override
  void initState() {
    // TODO: implement initState
    super.initState();



    WiFiForIoTPlugin.isConnected().then((value){
      if(value==true){
        print("wifiye bağlı");
      }
      else{
        print("wifiye bağlı değil");




        WiFiForIoTPlugin.forceWifiUsage(true);


        WiFiForIoTPlugin.connect(_SSID,password: _sifresi,withInternet: true,joinOnce: true).then((value){
          if(value==true) {
            print("2. deneme bağlantı başarılı");
          }
          else{
            print("2. deneme bağlantı başarısız");
          }

        });

        WiFiForIoTPlugin.registerWifiNetwork(_SSID,password: _sifresi).then((value){
          if(value==true){
            print("wifi kayıt oldu");
          }
          else {
            print("wifi kayıt oldu");
          }

        });

        WiFiForIoTPlugin.forceWifiUsage(false);



      }
    });


    //WiFiForIoTPlugin.showWritePermissionSettings(true);

    Timer.periodic(const Duration(seconds: 10), (Timer timer) async {
      String? ismiNe = await WiFiForIoTPlugin.getSSID();




      if (ismiNe==_SSID) {
        print('Bağlantı var.Cihazın adı $ismiNe');
        // Bağlantı olduğunda yapılacak işlemler
        setState(() {
          _cihazBagliMi=true;
          _cihazAdi=_SSID;
        });

      } else {
        print('Bağlantı yok');
        // Bağlantı olmadığında yapılacak işlemler

        setState(() {
          _cihazBagliMi = false;
          _cihazAdi = '';
          if(tekSefer==true){
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return UyariMesaji(
                  baslik: 'Uyarı',
                  icerik: 'Cihazla bağlantınız koptu. Lütfen Bağlan butonuna basınız.',
                  onaylaButonu: () {
                    //WifiyeBaglan(_SSID, _sifresi);
                    // Onaylama işlemi
                    Navigator.of(context).pop(); // Dialog'u kapat

                  },
                  iptalButonu: () {
                    // İptal işlemi
                    Navigator.of(context).pop(); // Dialog'u kapat
                  },
                );
              },
            );
            tekSefer=false;
          }
        });
      }
    });

  }

  @override
  void dispose() {
    // TODO: implement dispose
    Timer.periodic(const Duration(seconds: 10), (Timer timer) {}).cancel();
    super.dispose();
    WiFiForIoTPlugin.forceWifiUsage(false);
    WiFiForIoTPlugin.disconnect();
  }
  @override
  Widget build(BuildContext context) {

    //telefonun ekranı döndürüldüğünde uygulama dönmeyecek şekilde ayarlamak için kullanılır
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Temas Controller',style: TextStyle(color: Colors.white,fontFamily: 'Myfont'),),
        backgroundColor: Colors.indigo,
        shadowColor: Colors.red,
        foregroundColor: Colors.orange,
        centerTitle: true,
        leading: IconButton(icon: Icon(Icons.wifi_find,color:_cihazBagliMi == false ? Colors.green:Colors.red,size: 35,),onPressed: (){
          if(_cihazBagliMi==false) {
            WifiyeBaglan(_SSID ,_sifresi);

          }
          else{
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                duration: const Duration(milliseconds: 1000),
                width: 300.0, // Width of the SnackBar.

                //padding: const EdgeInsets.symmetric(
                //  horizontal: 8.0, // Inner padding for SnackBar content.
                //),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(35.0),
                ),
                // mobil uygulama herhangi bir cihaza bağlıysa yazılacak text bağlı değilse yazılacaklar
                content:
                Text("$_cihazAdi cihazına zaten bağlı.")
                ,
              ),
            );
          }

        },),
        automaticallyImplyLeading: false,//true da geri tuşu çıkıyor.
        actions: [

          IconButton(
            icon: Icon(Icons.wifi,
                //bağlantıya göre kırmızı veya yeşil rengi alması için
                color: _baglaniyorMu == false &&
                    _cihazBagliMi == true
                    ? Colors.green //şart sağlanırsa bu çalışır
                    : Colors.red, //sağlanmaz ise bu çalışır
                size: 35.0),
            //ikonun üzerine uzun basıldığında çıkan yazı
            tooltip: 'Cihaz ile Bağlantı Durumu',
            //ikona basıldığında yapılacaklar için
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(milliseconds: 1000),
                  width: 300.0, // Width of the SnackBar.

                  //padding: const EdgeInsets.symmetric(
                  //  horizontal: 8.0, // Inner padding for SnackBar content.
                  //),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(35.0),
                  ),
                  // mobil uygulama herhangi bir cihaza bağlıysa yazılacak text bağlı değilse yazılacaklar
                  content: _cihazAdi != '' &&
                      _cihazBagliMi == true
                      ? Text("$_cihazAdi CİHAZINA BAĞLI")
                      : const Text('BAĞLANTI YOK'),
                ),
              );
            },
          )
        ],
      ),
      body: WillPopScope(
        onWillPop: () => _onWillPop(context) ,
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Expanded(flex: 1,child: SizedBox(width: 10,height: 10,),),
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(24),color: Colors.white, boxShadow: const [
                      BoxShadow(color: Colors.indigo, spreadRadius: 2),
                    ],),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Expanded(

                            child: Text("Monitör",style: TextStyle(fontStyle: FontStyle.italic,color: Colors.indigo,fontSize: 16,fontFamily: 'Myfont'),)),
                        Expanded(
                          flex: 2,
                          child: IconButton(
                            highlightColor: Colors.indigoAccent,
                            iconSize: 64,
                            icon: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 350),
                                transitionBuilder: (child, anim) => RotationTransition(
                                  turns: child.key == const ValueKey('icon1')
                                      ? Tween<double>(begin: 1, end: 0).animate(anim)
                                      : Tween<double>(begin: 0, end: 1).animate(anim),
                                  child: ScaleTransition(scale: anim, child: child),
                                ),
                                child: _currIndex == 0
                                    ? const Icon(Icons.arrow_upward, key: ValueKey('icon1'),color: Colors.orange,)
                                    : const Icon(
                                  Icons.monitor,
                                  key: ValueKey('icon2'),color: Colors.indigo,
                                )),
                            onPressed: () {
                              setState(() {

                                _currIndex = _currIndex == 0 ? 1 : 0;
                                if(_currIndex==0) {
                                  //ESP32 ye komut gönderme işlemleri burada yapılır.
                                  monitorAltaKomutGonderFonk('monitor1Down');
                                }
                                else {
                                  monitorYukariKomutGonderFonk('monitor1Up');
                                }
                                _currIndex2=0;



                              });
                            },
                          ),
                        ),
                        Expanded(flex: 3,child: Image.asset("assets/icons/meeting_table.png")),

                        Expanded(
                          flex: 2,
                          child: IconButton(

                            highlightColor: Colors.indigoAccent,
                            iconSize: 64,
                            icon: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 350),
                                transitionBuilder: (child, anim) => RotationTransition(
                                  turns: child.key == const ValueKey('icon1')
                                      ? Tween<double>(begin: 1, end: 0).animate(anim)
                                      : Tween<double>(begin: 0, end: 1).animate(anim),
                                  child: ScaleTransition(scale: anim, child: child),
                                ),
                                child: _currIndex2 == 0
                                    ? const Icon(Icons.arrow_downward, key: ValueKey('icon1'),color: Colors.orange,)
                                    : const Icon(
                                  Icons.monitor,
                                  key: ValueKey('icon2'),color: Colors.indigo,
                                )),
                            onPressed: () {
                              setState(() {
                                _currIndex2 = _currIndex2 == 0 ? 1 : 0;
                                _currIndex=0;
                                //ESP32 ye komut gönderme işlemleri burada yapılır.
                                monitorAltaKomutGonderFonk('monitor1Down');
                              });
                            },
                          ),
                        ),

                      ],
                    ),
                  ),
                ),
                const Expanded(
                    flex: 1,
                    child: SizedBox(width: 20,height: 20,)),

              ],
            ),
          ),
        ),
      ),
    );
  }
}




class UyariMesaji extends StatelessWidget {
  final String baslik;
  final String icerik;
  final VoidCallback? onaylaButonu;
  final VoidCallback? iptalButonu;

  const UyariMesaji({
    Key? key,
    required this.baslik,
    required this.icerik,
    this.onaylaButonu,
    this.iptalButonu,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius:BorderRadius.circular(18),side: const BorderSide(color: Colors.indigo,width: 2)),
      title: Text(baslik,style: const TextStyle(color: Colors.orange,fontStyle: FontStyle.italic),),
      content: Text(icerik),
      actions: <Widget>[
        if (iptalButonu != null)
          TextButton(
            style: ButtonStyle(
                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                        side: const BorderSide(color: Colors.red,width: 2)
                    )
                )
            ),
            onPressed: iptalButonu,
            child: const Text('İptal'),
          ),
        if (onaylaButonu != null)
          TextButton(
            style: ButtonStyle(
                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                        side: const BorderSide(color: Colors.green,width: 2)
                    )
                )
            ),
            onPressed: onaylaButonu,
            child: const Text('Onayla'),
          ),
      ],
    );
  }
}


