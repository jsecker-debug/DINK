
"use client";

import React, { useState, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Menu, X } from "lucide-react";
import { cn } from "@/lib/utils";
import { useLocation, useNavigate } from "react-router-dom";
import { navigationItems } from "@/components/sidebar/navigation-items";
import { useAuth } from "@/contexts/AuthContext";
import { supabase } from "@/lib/supabase";
import { Avatar, AvatarImage, AvatarFallback } from "@/components/ui/avatar";

export function Sidebar({
  children,
  className,
}: {
  children: React.ReactNode;
  className?: string;
}) {
  const [open, setOpen] = useState(false);
  const [isMobile, setIsMobile] = useState(false);
  const [avatarUrl, setAvatarUrl] = useState<string | null>(null);
  const location = useLocation();
  const navigate = useNavigate();
  const { user } = useAuth();

  const userName = user?.user_metadata?.full_name || user?.email?.split('@')[0] || '';

  useEffect(() => {
    const checkMobile = () => {
      setIsMobile(window.innerWidth < 768);
    };
    checkMobile();
    window.addEventListener('resize', checkMobile);
    return () => window.removeEventListener('resize', checkMobile);
  }, []);

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
    <div
      className={cn(
        "flex flex-col md:flex-row w-full h-screen overflow-hidden",
        className
      )}
    >
      <div className="hidden md:flex flex-col">
        <motion.div
          className={cn(
            "h-full px-4 py-4 flex flex-col bg-white dark:bg-neutral-800 flex-shrink-0 border-r border-neutral-200 dark:border-neutral-700",
            "duration-200 transition-[width] ease-linear"
          )}
          animate={{
            width: open ? "300px" : "76px",
          }}
          onMouseEnter={() => !isMobile && setOpen(true)}
          onMouseLeave={() => !isMobile && setOpen(false)}
        >
          <div className="flex flex-col flex-1 overflow-y-auto overflow-x-hidden">
            {open ? <Logo /> : <LogoIcon />}
            <div className="mt-8 flex flex-col gap-2">
              {navigationItems.map((item, idx) => (
                <button
                  key={idx}
                  onClick={() => navigate(item.path)}
                  className={cn(
                    "flex items-center gap-4 p-3 rounded-lg transition-colors",
                    "min-h-[44px]",
                    location.pathname === item.path
                      ? "bg-primary text-white hover:bg-primary/90"
                      : "hover:bg-gray-100 text-neutral-700 dark:text-neutral-200"
                  )}
                >
                  <item.icon className="h-5 w-5 flex-shrink-0" />
                  <motion.span
                    initial={{ opacity: 0 }}
                    animate={{ opacity: open ? 1 : 0 }}
                    className="whitespace-pre"
                  >
                    {item.title}
                  </motion.span>
                </button>
              ))}
            </div>
          </div>
        </motion.div>
      </div>

      {/* Mobile Menu */}
      <div className="md:hidden fixed top-0 left-0 z-50 w-full">
        <div className="flex justify-start p-4">
          <Menu
            className="text-neutral-800 dark:text-neutral-200 cursor-pointer h-6 w-6"
            onClick={() => setOpen(!open)}
          />
        </div>
        <AnimatePresence>
          {open && (
            <motion.div
              initial={{ x: "-100%", opacity: 0 }}
              animate={{ x: 0, opacity: 1 }}
              exit={{ x: "-100%", opacity: 0 }}
              transition={{ duration: 0.3, ease: "easeInOut" }}
              className="fixed inset-0 bg-white dark:bg-neutral-900 p-6"
            >
              <div className="flex justify-between items-center mb-8">
                <Logo />
                <div className="flex items-center gap-2">
                  <Avatar 
                    className="h-8 w-8 cursor-pointer"
                    onClick={() => {
                      navigate('/profile');
                      setOpen(false);
                    }}
                  >
                    <AvatarImage 
                      src={avatarUrl || undefined} 
                      className="object-cover"
                    />
                    <AvatarFallback className="text-sm bg-white/20 text-white">
                      {userName[0]?.toUpperCase()}
                    </AvatarFallback>
                  </Avatar>
                  <X
                    className="text-neutral-800 dark:text-neutral-200 cursor-pointer h-6 w-6"
                    onClick={() => setOpen(false)}
                  />
                </div>
              </div>
              <div className="flex flex-col gap-2">
                {navigationItems.map((item, idx) => (
                  <button
                    key={idx}
                    onClick={() => {
                      navigate(item.path);
                      setOpen(false);
                    }}
                    className={cn(
                      "flex items-center gap-4 p-3 rounded-lg transition-colors min-h-[44px]",
                      location.pathname === item.path
                        ? "bg-primary text-white hover:bg-primary/90"
                        : "hover:bg-gray-100 text-neutral-700 dark:text-neutral-200"
                    )}
                  >
                    <item.icon className="h-5 w-5 flex-shrink-0" />
                    <span>{item.title}</span>
                  </button>
                ))}
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      <main className="flex-1 bg-white dark:bg-neutral-900 min-h-screen overflow-auto">
        {children}
      </main>
    </div>
  );
}

const Logo = () => {
  return (
    <div className="font-normal flex items-center gap-3 text-sm text-black py-1 relative z-20">
      <img 
        src="/lovable-uploads/0ff7ce02-62e2-4665-b101-44281d8d042c.png"
        alt="PickleHub Logo"
        className="h-8 w-8 rounded-full object-cover"
      />
      <motion.span
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        className="font-emblema-one text-black dark:text-white whitespace-pre text-2xl"
      >
        DINK
      </motion.span>
    </div>
  );
};

const LogoIcon = () => {
  return (
    <div className="font-normal flex items-center text-sm text-black py-1 relative z-20">
      <img 
        src="/lovable-uploads/0ff7ce02-62e2-4665-b101-44281d8d042c.png"
        alt="PickleHub Logo"
        className="h-8 w-8 rounded-full object-cover"
      />
    </div>
  );
}; 
