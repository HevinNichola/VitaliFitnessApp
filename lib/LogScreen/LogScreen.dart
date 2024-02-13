import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'LogScreenResources/DataBottomSheet.dart';
import 'LogScreenResources/LogBottomSheet.dart';
import 'LogScreenResources/PercentIndicator.dart';
import 'package:food_icons/food_icons.dart';

import 'LogScreenResources/getItemIcon.dart';

class LogScreen extends StatefulWidget {
  static const String id = "addtraindetails-screen";

  @override
  _LogScreenState createState() => _LogScreenState();
}


class _LogScreenState extends State<LogScreen> {

  DateTime logDate = DateTime.now();

  Map<String, Map<String, dynamic>> breakfastItems = {};
  Map<String, Map<String, dynamic>> lunchItems = {};
  Map<String, Map<String, dynamic>> dinnerItems = {};
  Map<String, Map<String, dynamic>> exercises = {};

  double totalCalories = 0;
  double totalProtein = 0;
  double totalCarbs = 0;
  double totalFat = 0;

  int iCalories = 0;

  Map<String, dynamic>? updateValues;

  Future<void> fetchData() async {
    String date = DateFormat('dd-MM-yyyy').format(logDate);

    final CollectionReference userDataCollection = FirebaseFirestore.instance.collection('User Data');
    final DocumentReference dateDocRef = userDataCollection.doc('test@gmail.com').collection('Dates').doc(date);

    try {
      DocumentSnapshot snapshot = await dateDocRef.get();
      if (snapshot.exists) {
        Map<String, dynamic>? userData = snapshot.data() as Map<String, dynamic>?;
        if (userData != null) {
          setState(() {
            breakfastItems = Map<String, Map<String, dynamic>>.from(userData['Breakfast log'] ?? {});
            lunchItems = Map<String, Map<String, dynamic>>.from(userData['Lunch log'] ?? {});
            dinnerItems = Map<String, Map<String, dynamic>>.from(userData['Dinner log'] ?? {});
            exercises = Map<String, Map<String, dynamic>>.from(userData['Exercise log'] ?? {});
            totalCalories = (userData['Calories'] ?? 0).toDouble();
            totalProtein = (userData['Protein'] ?? 0).toDouble();
            totalCarbs = (userData['Carbs'] ?? 0).toDouble();
            totalFat = (userData['Fat'] ?? 0).toDouble();
            print(breakfastItems);
          });
        }
      } else {
        setState(() {
          breakfastItems = {};
          lunchItems = {};
          dinnerItems = {};
          exercises = {};
          totalCalories = 0;
          totalProtein = 0;
          totalCarbs = 0;
          totalFat = 0;
        });
        print('Document does not exist');
      }
    } catch (error) {
      print('Error fetching document: $error');
    }
  }

  Future<void> updateData() async {
    String date = DateFormat('dd-MM-yyyy').format(logDate);

    final CollectionReference userDataCollection = FirebaseFirestore.instance.collection('User Data');
    final DocumentReference userDocRef = userDataCollection.doc('test@gmail.com');
    final CollectionReference dateCollection = userDocRef.collection('Dates');
    final DocumentReference dateDocRef = dateCollection.doc(date);

    dateDocRef.set({
      'Breakfast log' : breakfastItems,
      'Lunch log': lunchItems,
      'Dinner log': dinnerItems,
      'Exercise log': exercises,
      'Calories': totalCalories,
      'Protein': totalProtein,
      'Carbs': totalCarbs,
      'Fat': totalFat,
    }).then((value){
      print('Successfully Updated');
    }).onError((error, stackTrace){
      print((error, stackTrace));
    });
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Center(
            child: Text(
              DateFormat('E dd').format(logDate),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {
                _selectDate(context);
              },
              icon: Icon(
                Icons.calendar_today,
                color: Colors.white,
              ),
            ),
          ],
          backgroundColor: Color(0xFF284494),
        ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(10),
          color: Colors.grey[200],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 30),
              showPercentIndicator(
                  caloriesPercentage: _calculatePercentage(totalCalories, 1500),
                  proteinPercentage: _calculatePercentage(totalProtein, 100),
                  carbsPercentage: _calculatePercentage(totalCarbs, 200),
                  fatPercentage: _calculatePercentage(totalFat, 50),
                  currentCalories: totalCalories,
                  currentProtein: totalProtein,
                  currentCarbs: totalCarbs,
                  currentFat: totalFat,
              ),
              SizedBox(height: 50),
              buildItemSection('Breakfast', breakfastItems, (selectedItem, newData) {
                setState(() {
                  breakfastItems[selectedItem] = newData;
                  _updateTotals(newData);
                });
              },
                updateData,
              ),
              buildItemSection('Lunch', lunchItems, (selectedItem, newData) {
                setState(() {
                  lunchItems[selectedItem] = newData;
                  _updateTotals(newData);
                });
              },
                updateData,
              ),
              buildItemSection('Dinner', dinnerItems, (selectedItem, newData) {
                setState(() {
                  dinnerItems[selectedItem] = newData;
                  _updateTotals(newData);
                });
              },
                updateData,
              ),
              buildItemSection('Exercise', exercises, (selectedItem, newData) {
                setState(() {
                  exercises[selectedItem] = newData;
                  _updateTotals(newData);
                });
              },
                updateData,
              ),
            ]
          )
        ),
      )
    );
  }

  Widget buildItemSection(String title, Map<String, Map<String, dynamic>> items, Function(String, Map<String, dynamic>) onSelect, Function() updateData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20.0,
          ),
        ),
        Divider(),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (BuildContext context, int index) {
            String itemName = items.keys.elementAt(index);
            Map<String, dynamic> itemData = items[itemName]!;
            print('=======$itemData');

            return GestureDetector(
              onTap: () {
                if (title != 'Exercise') {
                  showDataBottomSheetForFood(
                    context,
                    bottomsheetTitle: itemName,
                    mealTime: title,
                    updateDate: logDate,
                    updateQuantity: itemData['quantity'],
                    updateCalories: itemData['calories'],
                    updateProtein: itemData['protein'],
                    updateCarbs: itemData['carbs'],
                    updateFat: itemData['fat'],
                    onSelect: (item, count, quantity, calories, protein, carb, fat) {
                      onSelect(item, {
                        'count': count,
                        'quantity': quantity,
                        'calories': calories,
                        'protein': protein ?? 0,
                        'carbs': carb ?? 0,
                        'fat': fat ?? 0,
                      });
                    },
                    updateData: updateData,
                    onUpdate: (calories, protein, carbs, fat){
                      setState(() {
                        updateValues = {
                          'calories': calories,
                          'protein': protein,
                          'carbs': carbs,
                          'fat': fat,
                        };
                      });
                    },
                    onDelete: (itemName, mealTime, percentages) {
                      setState(() {
                        _deleteFromTotal(percentages);
                        if (mealTime == 'Breakfast') {
                          breakfastItems.remove(itemName);
                        } else if (mealTime == 'Lunch') {
                          lunchItems.remove(itemName);
                        } else if (mealTime == 'Dinner') {
                          dinnerItems.remove(itemName);
                        }
                      });
                      print('==============perc===============$percentages');
                    },
                  );
                } else{
                  showDataBottomSheetForExercise(
                    context,
                    bottomsheetTitle: itemName,
                    updateLastDropdownValue: itemData['count'],
                    updateSessionTime: itemData['quantity'].toString(),
                    updateDate: logDate,
                    updateCalories: itemData['calories'],
                    onSelect: (item, count, sessionTime, calories) {
                      onSelect(item, {
                        'count': count,
                        'quantity': sessionTime,
                        'calories': calories,
                      });
                      print(calories);
                    },
                    updateData: updateData,
                    onUpdate: (calories){
                      setState(() {
                        updateValues = {
                          'calories': calories,
                        };
                      });
                    },
                    onDelete: (itemName, mealTime, percentages) {
                      setState(() {
                        _deleteFromTotal(percentages);
                        if (mealTime == 'Exercise') {
                          exercises.remove(itemName);
                        }
                      });
                      print('==============perc===============$percentages');
                    },
                  );
                }
              },
              child: ListTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (title != 'Exercise')
                          Icon(
                            getFoodIcon(itemData['type'] ?? '')[0],
                            size: 16,
                            color: getFoodIcon(itemData['type'] ?? '')[1],
                          ),

                          if (title == 'Exercise')
                            Icon(
                              getExerciseIcon(itemName ?? '')[0],
                              size: 16,
                              color: getExerciseIcon(itemName ?? '')[1],
                            ),

                          SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(itemName),
                              Text(
                                itemData['type'] ?? '',
                                style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                                ),
                                ),
                            ],
                          ),
                          Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                ('${itemData['quantity']} (${itemData['count']})'),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                ('${itemData['calories']} kcal'),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: 10),
                          Icon(
                            Icons.check_circle,
                            size: 22,
                            color: Colors.green,
                          ),
                        ],
                      ),
                      Divider(),
                    ],
                  ),
                  ),
            );
          },
        ),
        SizedBox(height:10),
        LogBottomSheet(
          bottomsheetTitle: title == 'Exercise' ? 'Exercise' : 'Food',
          mealTime: title,
          onSelect: (item, type, count, quantity, calories, protein, carb, fat){
            onSelect(item, {
              'type': type,
              'count': count,
              'quantity': quantity,
              'calories': calories,
              'protein': protein ?? 0,
              'carbs': carb ?? 0,
              'fat': fat ?? 0,
            });
          },
          updateData: updateData,
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: logDate,
      firstDate: DateTime(2015, 8),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != logDate) {
      setState(() {
        logDate = picked;
        fetchData();
      });
    }
  }

  Future<void> _updateTotals(Map<String, dynamic> newData) async {
    setState(() {
      if (updateValues != null){
        print('inside update');
        totalCalories += updateValues?['calories'] ?? 0.0;
        totalProtein += updateValues?['protein'] ?? 0.0;
        totalCarbs += updateValues?['carbs'] ?? 0.0;
        totalFat += updateValues?['fat'] ?? 0.0;

        updateValues?.clear();
        updateValues = null;
      } else {
        print('inside new');
        totalCalories += newData['calories'] ?? 0.0;
        totalProtein += newData['protein'] ?? 0.0;
        totalCarbs += newData['carbs'] ?? 0.0;
        totalFat += newData['fat'] ?? 0.0;
      }
    });
  }

  void _deleteFromTotal(Map<String, dynamic> percentages) {
    setState(() {
      totalCalories -= percentages['calories'] ?? 0.0;
      totalProtein -= percentages['protein'] ?? 0.0;
      totalCarbs -= percentages['carbs'] ?? 0.0;
      totalFat -= percentages['fat'] ?? 0.0;

    });
  }

  double _calculatePercentage(double value, double target) {
    if (value <= 0) {
      return 0.0;
    } else if (value >= target) {
      return 1.0;
    } else {
      return value / target;
    }
  }

  // void removeItem(String title, String itemToRemove) {
  //   switch (title) {
  //     case 'Breakfast':
  //       if (breakfastItems.contains(itemToRemove)) {
  //           breakfastItems.remove(itemToRemove);
  //       }
  //       break;
  //     case 'Lunch':
  //       if (lunchItems.contains(itemToRemove)) {
  //         lunchItems.remove(itemToRemove);
  //         print('deleted');
  //       }
  //       break;
  //     case 'Dinner':
  //       if (dinnerItems.contains(itemToRemove)) {
  //         dinnerItems.remove(itemToRemove);
  //         print('deleted');
  //       }
  //       break;
  //     case 'Exercise':
  //       if (exercises.contains(itemToRemove)) {
  //         exercises.remove(itemToRemove);
  //         print('deleted');
  //       }
  //       break;
  //     default:
  //       print('Invalid title: $title');
  //   }
  // }
}