import { Calendar, Users, Clock, Home } from "lucide-react";

export const navigationItems = [
  {
    title: "Home",
    icon: Home,
    path: "/home",
  },
  {
    title: "Scheduler",
    icon: Calendar,
    path: "/scheduler",
  },
  {
    title: "Participants",
    icon: Users,
    path: "/participants",
  },
  {
    title: "Sessions",
    icon: Clock,
    path: "/sessions",
  },
];
