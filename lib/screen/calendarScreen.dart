import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_application_1/controllers/eventController.dart';

class CalendarScreen extends StatelessWidget {
  final EventController eventController = Get.put(EventController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCE6E6),
      appBar: AppBar(
        title: const Text("Calendari"),
        backgroundColor: const Color(0xFF89AFAF),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              //Calendari
              Obx(() => Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFB2D5D5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2020, 01, 01),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: eventController.focusedDay.value,
                      startingDayOfWeek: StartingDayOfWeek.monday, // Setmana comença dilluns
                      selectedDayPredicate: (day) =>
                          isSameDay(eventController.selectedDay.value, day),
                      onDaySelected: eventController.onDaySelected,
                      onPageChanged: (focusedDay) {
                        eventController.focusedDay.value = focusedDay;
                      },
                      calendarStyle: CalendarStyle(
                        selectedDecoration: BoxDecoration(
                          color: Color(0xFF89AFAF), // Color del dia seleccionat
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: Color(0xFF89AFAF), // Color del dia d'avui
                          shape: BoxShape.circle,
                        ),
                        defaultDecoration: BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        weekendDecoration: BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: BoxDecoration(
                          color: Colors.purpleAccent, // Color per als dies amb esdeveniments
                          shape: BoxShape.circle,
                        ),
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        leftChevronIcon:
                            Icon(Icons.chevron_left, color: Colors.black),
                        rightChevronIcon:
                            Icon(Icons.chevron_right, color: Colors.black),
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: TextStyle(color: Colors.black),
                        weekendStyle: TextStyle(color: Colors.black),
                      ),
                      eventLoader: (day) =>
                          eventController.getEventsForDay(day), // Marca els dies amb esdeveniments
                    ),
                  )),
              SizedBox(height: 16),
              // Llista d'esdeveniments per al dia seleccionat
              Obx(() {
                final selectedEvents = eventController.getEventsForDay(eventController.selectedDay.value);
                return Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFB2D5D5), // Color del fons
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Esdeveniments del dia seleccionat",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 8),
                      selectedEvents.isEmpty
                          ? Center(
                              child: Text(
                                "No hi ha esdeveniments per a aquest dia.",
                                style: TextStyle(color: Colors.black54),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true, // Impedeix que ocupi tot l'espai disponible
                              physics: NeverScrollableScrollPhysics(), // Evita conflictes amb el scroll principal
                              itemCount: selectedEvents.length,
                              itemBuilder: (context, index) {
                                final event = selectedEvents[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    event.name,
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(event.description),
                                  trailing: Text(
                                    "${event.eventDate.hour}:${event.eventDate.minute.toString().padLeft(2, '0')}",
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                );
              }),


            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddEventDialog(context);
        },
        backgroundColor: const Color(0xFF89AFAF),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddEventDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return GetBuilder<EventController>(
          builder: (eventController) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Nou Esdeveniment',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF89AFAF),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: eventController.nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: eventController.descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Descripció',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: eventController.dateController,
                        decoration: const InputDecoration(
                          labelText: 'Data (YYYY-MM-DD)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: eventController.creatorController,
                        decoration: const InputDecoration(
                          labelText: 'Creador',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: () async {
                            await eventController.createEvent();
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF89AFAF),
                          ),
                          child: const Text('Crear Esdeveniment'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
