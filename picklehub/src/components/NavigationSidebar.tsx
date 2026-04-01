"use client";

import React, { useState, useEffect } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { navigationItems } from "@/components/sidebar/navigation-items";
import { useAuth } from "@/contexts/AuthContext";
import { supabase } from "@/lib/supabase";
import { Avatar, AvatarImage, AvatarFallback } from "@/components/ui/avatar";
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

export function NavigationSidebar({
  children,
}: {
  children: React.ReactNode;
}) {
  const [avatarUrl, setAvatarUrl] = useState<string | null>(null);
  const location = useLocation();
  const navigate = useNavigate();
  const { user } = useAuth();

  const userName = user?.user_metadata?.full_name || user?.email?.split('@')[0] || '';

  useEffect(() => {
    if (user) {
      fetchAvatarUrl();
    }
  }, [user]);

  const fetchAvatarUrl = async () => {
    try {
      // First try to get the URL from the participants table
      const { data: participant } = await supabase
        .from('participants')
        .select('avatar_url')
        .eq('id', user?.id)
        .single();

      if (participant?.avatar_url) {
        // If URL already has a timestamp, use it as is
        if (participant.avatar_url.includes('?v=')) {
          setAvatarUrl(participant.avatar_url);
        } else {
          // Add timestamp to prevent caching
          const timestamp = new Date().getTime();
          setAvatarUrl(`${participant.avatar_url}?v=${timestamp}`);
        }
        return;
      }

      // Fallback to checking storage directly
      const { data: files } = await supabase
        .storage
        .from('profile_pictures')
        .list(`${user?.id}`, {
          limit: 1,
          sortBy: { column: 'name', order: 'desc' }
        });

      if (files && files.length > 0) {
        const { data: urlData } = await supabase
          .storage
          .from('profile_pictures')
          .getPublicUrl(`${user?.id}/${files[0].name}`);
        
        if (urlData?.publicUrl) {
          const timestamp = new Date().getTime();
          setAvatarUrl(`${urlData.publicUrl}?v=${timestamp}`);
        }
      }
    } catch (error) {
      console.error('Error fetching avatar URL:', error);
    }
  };

  return (
    <SidebarProvider defaultOpen={true}>
      <Sidebar collapsible="none" className="border-sidebar-border">
        <SidebarHeader className="p-4">
          <div className="flex items-center gap-3">
            <img 
              src="/lovable-uploads/0ff7ce02-62e2-4665-b101-44281d8d042c.png"
              alt="PickleHub Logo"
              className="h-8 w-8 rounded-full object-cover"
            />
            <span className="font-emblema-one text-sidebar-foreground text-2xl">
              DINK
            </span>
          </div>
        </SidebarHeader>
        
        <SidebarContent>
          <SidebarGroup>
            <SidebarGroupContent>
              <SidebarMenu>
                {navigationItems.map((item) => (
                  <SidebarMenuItem key={item.path}>
                    <SidebarMenuButton
                      onClick={() => navigate(item.path)}
                      isActive={location.pathname === item.path}
                      className="w-full justify-start"
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

        <SidebarFooter className="p-4">
          <div 
            className="flex items-center gap-3 p-2 rounded-lg hover:bg-sidebar-accent cursor-pointer transition-colors"
            onClick={() => navigate('/profile')}
          >
            <Avatar className="h-8 w-8">
              <AvatarImage 
                src={avatarUrl || undefined} 
                className="object-cover"
              />
              <AvatarFallback className="text-sm bg-sidebar-accent text-sidebar-accent-foreground">
                {userName[0]?.toUpperCase()}
              </AvatarFallback>
            </Avatar>
            <div className="flex flex-col">
              <span className="text-sm font-medium text-sidebar-foreground">
                {userName}
              </span>
              <span className="text-xs text-sidebar-foreground/70">
                {user?.email}
              </span>
            </div>
          </div>
        </SidebarFooter>
      </Sidebar>
      
      <SidebarInset>
        {children}
      </SidebarInset>
    </SidebarProvider>
  );
}