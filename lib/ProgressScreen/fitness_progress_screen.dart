import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:vitali/ProgressScreen/user_profile_screen.dart';

class FitnessProgress extends StatefulWidget {
  final String userEmail;

  const FitnessProgress({Key? key, required this.userEmail}) : super(key: key);

  @override
  State<FitnessProgress> createState() => _FitnessProgressState();
}

class _FitnessProgressState extends State<FitnessProgress> {
  Map<String, dynamic> userData = {};

  double totalCalories = 0;
  double totalProtein = 0;
  double totalCarbs = 0;
  double totalFat = 0;
  late SharedPreferences prefs;
  late String email;
  double targetCalories = 25000;
  double targetProtein = 2800;
  double targetCarbs = 5600;
  double targetFat = 1400;

  @override
  void initState() {
    super.initState();
    initializePreferences();
  }

  Future<void> initializePreferences() async {
    prefs = await SharedPreferences.getInstance();
    email = prefs.getString('Email') ?? '';
    fetchData();
  }

  Future<void> fetchData() async {
    final CollectionReference userDataCollection = FirebaseFirestore.instance
        .collection('User Data')
        .doc(email)
        .collection('Dates');

    try {
      QuerySnapshot querySnapshot = await userDataCollection.get();

      querySnapshot.docs.forEach((DocumentSnapshot document) {
        Map<String, dynamic>? userData =
        document.data() as Map<String, dynamic>?;

        if (userData != null) {
          setState(() {
            totalCalories += (userData['Calories'] ?? 0).toDouble();
            totalProtein += (userData['Protein'] ?? 0).toDouble();
            totalCarbs += (userData['Carbs'] ?? 0).toDouble();
            totalFat += (userData['Fat'] ?? 0).toDouble();
            updateLocalData(userData);
          });
        }
      });
      setState(() {
        userData = {
          'Calories': totalCalories,
          'Protein': totalProtein,
          'Carbs': totalCarbs,
          'Fat': totalFat,
        };
      });
    } catch (e) {}
  }

  Future<void> updateLocalData(Map<String, dynamic> userData) async {
    final Database db = await openDatabase(
      join(await getDatabasesPath(), 'user_data.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE user_data(calories INTEGER, protein INTEGER, carbs INTEGER, fat INTEGER)",
        );
      },
      version: 1,
    );

    await db.insert(
      'user_data',
      {
        'calories': userData['Calories'] ?? 0,
        'protein': userData['Protein'] ?? 0,
        'carbs': userData['Carbs'] ?? 0,
        'fat': userData['Fat'] ?? 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>> getLocalData() async {
    final Database db = await openDatabase(
      join(await getDatabasesPath(), 'user_data.db'),
    );

    final List<Map<String, dynamic>> userRecords = await db.query('user_data');

    if (userRecords.isNotEmpty) {
      return userRecords.first;
    }

    return {
      'calories': 0,
      'protein': 0,
      'carbs': 0,
      'fat': 0,
    };
  }

  double calculatePercent(double consumed, double target) {
    double percent = consumed / target;
    return percent.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF284494),
        centerTitle: true,
        elevation: 0,
        title: const Text(
          "Progress",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFF3FCFF),
                  Color(0xFFFFFFFF),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 20),
                // Add the text here
                const Center(
                  child:Text(
                  'Track Your Progress Here!',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF01AAEC),
                  ),
                ),
                ),
                const SizedBox(height: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Calories',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15,),
                    SizedBox(
                      height: 200.0,
                      child: CircularPercentIndicator(
                        radius: 100.0,
                        lineWidth: 15.0,
                        percent: calculatePercent(totalCalories, targetCalories),
                        center: Text(
                          '${userData['Calories'] ?? "Loading..."} / $targetCalories',
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        circularStrokeCap: CircularStrokeCap.round,
                        progressColor: Colors.blue,
                        backgroundColor: const Color(0xFFEAEDF5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Protein',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      height: 50.0,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15.0),
                          color: Colors.transparent,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25.0),
                        child: LinearPercentIndicator(
                          lineHeight: 30.0,
                          percent: calculatePercent(totalProtein, targetProtein),
                          center: Text(
                            '${userData['Protein'] ?? "Loading..."} / $targetProtein',
                            style: const TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          linearGradient: const LinearGradient(
                            colors: [Color(0xFF2BEEFB), Color(0xFF2BEEFB)],
                          ),
                          clipLinearGradient: true,
                          backgroundColor: const Color(0xFFEAEDF5),
                          padding: EdgeInsets.zero,
                        ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Carbs',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      height: 50.0,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15.0),
                          color: Colors.transparent,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25.0),
                        child: LinearPercentIndicator(
                          lineHeight: 30.0,
                          percent: calculatePercent(totalCarbs, targetCarbs),
                          center: Text(
                            '${userData['Carbs'] ?? "Loading..."} / $targetCarbs',
                            style: const TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          linearGradient: const LinearGradient(
                            colors: [Color(0xFF7B80FF), Color(0xFF7B80FF)],
                          ),
                          clipLinearGradient: true,
                          backgroundColor: const Color(0xFFEAEDF5),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fat',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      height: 50.0,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15.0),
                          color: Colors.transparent,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25.0),
                        child: LinearPercentIndicator(
                          lineHeight: 30.0,
                          percent: calculatePercent(totalFat, targetFat),
                          center: Text(
                            '${userData['Fat'] ?? "Loading..."} / $targetFat',
                            style: const TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          linearGradient: const LinearGradient(
                            colors: [Color(0xFF49C8FF), Color(0xFF49C8FF)],
                          ),
                          clipLinearGradient: true,
                          backgroundColor: const Color(0xFFEAEDF5),
                          padding: EdgeInsets.zero,
                        ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileView(userEmail: ''),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0C2D57),
                    elevation: 3,
                    padding: const EdgeInsets.all(15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "View Profile",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

