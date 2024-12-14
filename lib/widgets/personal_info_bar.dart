import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:spotify_project/Business_Logic/firestore_database_service.dart';

class PersonalInfoNameBar extends StatefulWidget {
  String label;
  int? lineCount;
  TextEditingController? controller;
  double? height;
  bool? isObscure = false;
  double? width;
  var methodToRun;
  PersonalInfoNameBar({
    Key? key,
    this.isObscure,
    this.lineCount,
    this.width,
    this.height,
    required this.label,
    this.controller,
    this.methodToRun,
  }) : super(key: key);

  @override
  State<PersonalInfoNameBar> createState() => _PersonalInfoNameBarState();
}

class _PersonalInfoNameBarState extends State<PersonalInfoNameBar> {
  FirestoreDatabaseService _firestoreDatabaseService =
      FirestoreDatabaseService();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: widget.width ?? MediaQuery.of(context).size.width - 160.w,
          height: widget.height,
          color: const Color.fromARGB(0, 182, 182, 182),
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            color: Colors.grey[900], // Changed card color to dark grey
            child: Padding(
              padding: EdgeInsets.only(left: 40.w, right: 15.w),
              child: TextFormField(
                  onChanged: (value) {
                    widget.methodToRun(value);
                  },
                  controller: widget.controller,
                  keyboardType: widget.label == "Price"
                      ? TextInputType.numberWithOptions()
                      : null,
                  obscureText: widget.isObscure ?? false,
                  style: TextStyle(
                      height: 0.9,
                      fontSize: 33.sp,
                      fontFamily: "Calisto",
                      fontWeight: FontWeight.w500,
                      color: Colors.white), // Changed text color to white
                  maxLines: widget.lineCount,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    label: Text(
                      widget.label,
                      style: TextStyle(
                          fontSize: 27,
                          fontFamily: "Calisto",
                          color: Colors
                              .grey[400]), // Changed label color to light grey
                    ),
                  )),
            ),
          ),
        ),
        SizedBox(
          height: widget.label == "What's your name?" ? 10 : 40,
        )
      ],
    );
  }
}
