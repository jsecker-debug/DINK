"use client";

import React from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { 
  LayoutDashboard, 
  MessageSquare, 
  Calendar, 
  Users, 
  Trophy,
  CreditCard,
  LogIn,
  UserPlus,
  Menu,
  X,
  Home
} from "lucide-react";
import { useState } from "react";
import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarGroup,
  SidebarGroupContent,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarProvider,
  SidebarInset,
} from "@/components/ui/sidebar";
import { useAuth } from "@/contexts/AuthContext";

const authenticatedNavigationItems = [
  {
    title: "Dashboard",
    icon: LayoutDashboard,
    path: "/dashboard",
  },
  {
    title: "Feed",
    icon: MessageSquare,
    path: "/feed",
  },
  {
    title: "Schedule",
    icon: Calendar,
    path: "/schedule",
  },
  {
    title: "Members",
    icon: Users,
    path: "/members",
  },
  {
    title: "Rankings",
    icon: Trophy,
    path: "/rankings",
  },
  {
    title: "Payments",
    icon: CreditCard,
    path: "/payments",
  },
];

const unauthenticatedNavigationItems = [
  {
    title: "Home",
    icon: Home,
    path: "/",
  },
  {
    title: "Sign In",
    icon: LogIn,
    path: "/signin",
  },
  {
    title: "Sign Up",
    icon: UserPlus,
    path: "/signup",
  },
];

export function ProductSidebar({
  children,
}: {
  children: React.ReactNode;
}) {
  const location = useLocation();
  const navigate = useNavigate();
  const { user, loading } = useAuth();
  
  // Show loading state while checking auth
  if (loading) {
    return (
      <div className="flex min-h-screen w-full items-center justify-center">
        <div className="text-muted-foreground">Loading...</div>
      </div>
    );
  }
  
  const navigationItems = user ? authenticatedNavigationItems : unauthenticatedNavigationItems;

  return (
    <SidebarProvider defaultOpen={true}>
      <div className="flex min-h-screen w-full">
        <Sidebar collapsible="none" className="border-r border-border bg-background flex-shrink-0">
          <SidebarHeader className="p-6">
            <div className="flex items-center gap-3">
              <img 
                src="/New_DINK.png"
                alt="DINK Logo"
                className="h-10 w-10 object-contain"
              />
              <div>
                <h1 className="font-emblema-one text-foreground text-2xl">
                  DINK
                </h1>
              </div>
            </div>
          </SidebarHeader>
          
          <SidebarContent className="flex-1">
            <SidebarGroup>
              <SidebarGroupContent>
                <SidebarMenu className="space-y-1">
                  {navigationItems.map((item) => (
                    <SidebarMenuItem key={item.path}>
                      <SidebarMenuButton
                        onClick={() => navigate(item.path)}
                        isActive={location.pathname === item.path}
                        className="w-full justify-start px-4 py-3 text-sm font-medium"
                        size="lg"
                      >
                        <item.icon className="h-5 w-5" />
                        <span>{item.title}</span>
                      </SidebarMenuButton>
                    </SidebarMenuItem>
                  ))}
                </SidebarMenu>
              </SidebarGroupContent>
            </SidebarGroup>
          </SidebarContent>

          <SidebarFooter className="p-6 mt-auto">
            <div className="text-xs text-muted-foreground">
              <p>© 2024 DINK</p>
              <p>Pickleball Club Management</p>
            </div>
          </SidebarFooter>
        </Sidebar>
        
        <div className="flex-1 flex flex-col min-w-0">
          {children}
        </div>
      </div>
    </SidebarProvider>
  );
}