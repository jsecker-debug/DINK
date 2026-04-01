import React from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { cn } from "@/lib/utils";
import { navigationItems } from "./navigation-items";
import {
  SidebarMenu,
  SidebarMenuItem,
  SidebarMenuButton,
} from "@/components/ui/sidebar";

export const NavigationMenu = () => {
  const navigate = useNavigate();
  const location = useLocation();

  return (
    <SidebarMenu>
      {navigationItems.map((item) => (
        <SidebarMenuItem key={item.title}>
          <SidebarMenuButton 
            onClick={() => navigate(item.path)}
            className={cn(
              "w-full rounded-lg transition-colors",
              location.pathname === item.path
                ? "bg-primary text-white hover:bg-primary/90"
                : "hover:bg-gray-100"
            )}
          >
            <item.icon className="h-4 w-4" />
            <span>{item.title}</span>
          </SidebarMenuButton>
        </SidebarMenuItem>
      ))}
    </SidebarMenu>
  );
};