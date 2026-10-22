import 'package:flutter/material.dart';

import '../../features/admin/admin_dashboard.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/student/dashboard/student_dashboard.dart';
import '../../features/teacher/dashboard/teacher_dashboard.dart';
import '../../features/teacher/classes/teacher_classes_screen.dart';
import '../../features/teacher/attendance/attendance_screen.dart';
import '../../features/teacher/profile/profile_setup_screen.dart';
import '../../features/teacher/planner/lecture_planner_screen.dart';
import '../../features/teacher/teacher_portal_routes.dart';
import '../../features/teacher/teacher_section_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String registerTeacher = '/register-teacher';
  static const String teacherProfileSetup = TeacherPortalRoutes.profile;
  static const String studentDashboard = '/student-dashboard';
  static const String teacherDashboard = TeacherPortalRoutes.home;
  static const String adminDashboard = '/admin-dashboard';
  static const String teacherClasses = TeacherPortalRoutes.classes;
  static const String teacherAttendance = TeacherPortalRoutes.attendance;
  static const String teacherAssignments = TeacherPortalRoutes.assignments;
  static const String teacherPlanner = TeacherPortalRoutes.timetable;
  static const String teacherTimetable = TeacherPortalRoutes.timetable;
  static const String teacherNotifications = TeacherPortalRoutes.notifications;
  static const String teacherMenu = TeacherPortalRoutes.menu;
  static const String teacherPlanLecture = TeacherPortalRoutes.planLecture;
  static const String teacherCreateQuiz = TeacherPortalRoutes.createQuiz;

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case registerTeacher:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case teacherProfileSetup:
        return MaterialPageRoute(builder: (_) => const ProfileSetupScreen());
      case teacherClasses:
        return MaterialPageRoute(builder: (_) => const TeacherClassesScreen());
      case teacherAttendance:
        return MaterialPageRoute(builder: (_) => const AttendanceScreen());
      case teacherAssignments:
        return MaterialPageRoute(
          builder: (_) => const TeacherSectionScreen(
            title: 'Assignments',
            activeRoute: teacherAssignments,
          ),
        );
      case teacherPlanner:
        return MaterialPageRoute(builder: (_) => const LecturePlannerScreen());
      case teacherNotifications:
        return MaterialPageRoute(
          builder: (_) => const TeacherSectionScreen(
            title: 'Notifications',
            activeRoute: teacherNotifications,
          ),
        );
      case teacherMenu:
        return MaterialPageRoute(
          builder: (_) => const TeacherSectionScreen(
            title: 'Menu',
            activeRoute: teacherMenu,
          ),
        );
      case teacherPlanLecture:
        return MaterialPageRoute(
          builder: (_) => LecturePlannerScreen(
            initialDate: settings.arguments is DateTime
                ? settings.arguments! as DateTime
                : null,
          ),
        );
      case teacherCreateQuiz:
        return MaterialPageRoute(
          builder: (_) => const TeacherSectionScreen(
            title: 'Create Quiz',
            activeRoute: teacherCreateQuiz,
          ),
        );
      case studentDashboard:
        return MaterialPageRoute(builder: (_) => const StudentDashboard());
      case teacherDashboard:
        return MaterialPageRoute(builder: (_) => const TeacherDashboard());
      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboard());
      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}
