import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { 
  MessageSquare, 
  Heart, 
  Share2, 
  Calendar,
  Trophy,
  Users,
  Clock,
  MessageCircle,
  PlusCircle
} from "lucide-react";
import { format, formatDistanceToNow } from "date-fns";
import { useState } from "react";
import { useClubActivity, useRecentSessions, useRecentMembers } from "@/hooks/useClubActivity";
import CreatePostDialog from "@/components/CreatePostDialog";

// Mock data for feed items - in a real app this would come from your backend
const mockFeedData = [
  {
    id: 1,
    type: "session_created",
    title: "New Session Scheduled",
    content: "A new pickleball session has been scheduled for this weekend at Riverside Courts.",
    author: {
      name: "Club Admin",
      avatar: "",
      initials: "CA"
    },
    timestamp: new Date(Date.now() - 2 * 60 * 60 * 1000), // 2 hours ago
    likes: 5,
    comments: 2,
    metadata: {
      date: "2024-01-15",
      venue: "Riverside Courts"
    }
  },
  {
    id: 2,
    type: "member_joined",
    title: "New Member Joined",
    content: "Sarah Johnson has joined the club! Welcome to the community.",
    author: {
      name: "Sarah Johnson",
      avatar: "",
      initials: "SJ"
    },
    timestamp: new Date(Date.now() - 6 * 60 * 60 * 1000), // 6 hours ago
    likes: 12,
    comments: 4,
    metadata: {
      level: 4.2
    }
  },
  {
    id: 3,
    type: "tournament_result",
    title: "Tournament Results",
    content: "Congratulations to Mike Chen and Lisa Parker for winning the doubles tournament!",
    author: {
      name: "Tournament Director",
      avatar: "",
      initials: "TD"
    },
    timestamp: new Date(Date.now() - 24 * 60 * 60 * 1000), // 1 day ago
    likes: 23,
    comments: 8,
    metadata: {
      winners: ["Mike Chen", "Lisa Parker"],
      tournament: "Spring Doubles"
    }
  },
  {
    id: 4,
    type: "announcement",
    title: "Court Maintenance Notice",
    content: "Courts 1 and 2 will be under maintenance this Thursday from 8 AM to 12 PM.",
    author: {
      name: "Facilities Manager",
      avatar: "",
      initials: "FM"
    },
    timestamp: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000), // 2 days ago
    likes: 3,
    comments: 1,
    metadata: {
      courts: [1, 2],
      maintenanceDate: "2024-01-18"
    }
  },
  {
    id: 5,
    type: "session_completed",
    title: "Session Completed",
    content: "Great games today! 16 players participated in today's session at Central Park Courts.",
    author: {
      name: "Session Host",
      avatar: "",
      initials: "SH"
    },
    timestamp: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000), // 3 days ago
    likes: 18,
    comments: 6,
    metadata: {
      participants: 16,
      venue: "Central Park Courts"
    }
  }
];

const getActivityIcon = (type: string) => {
  switch (type) {
    case "session_created":
      return <Calendar className="h-5 w-5 text-chart-1" />;
    case "session_completed":
      return <Clock className="h-5 w-5 text-chart-2" />;
    case "session_cancelled":
      return <Calendar className="h-5 w-5 text-red-500" />;
    case "member_joined":
      return <Users className="h-5 w-5 text-chart-3" />;
    case "tournament_result":
      return <Trophy className="h-5 w-5 text-chart-4" />;
    case "announcement":
      return <MessageSquare className="h-5 w-5 text-chart-5" />;
    default:
      return <MessageCircle className="h-5 w-5 text-muted-foreground" />;
  }
};

const getActivityBadge = (type: string) => {
  switch (type) {
    case "session_created":
      return <Badge variant="secondary" className="bg-chart-1/10 text-chart-1">Available</Badge>;
    case "session_completed":
      return <Badge variant="secondary" className="bg-chart-2/10 text-chart-2">Completed</Badge>;
    case "session_cancelled":
      return <Badge variant="secondary" className="bg-red-500/10 text-red-500">Cancelled</Badge>;
    case "member_joined":
      return <Badge variant="secondary" className="bg-chart-3/10 text-chart-3">New Member</Badge>;
    case "tournament_result":
      return <Badge variant="secondary" className="bg-chart-4/10 text-chart-4">Tournament</Badge>;
    case "announcement":
      return <Badge variant="secondary" className="bg-chart-5/10 text-chart-5">Announcement</Badge>;
    default:
      return <Badge variant="outline">Activity</Badge>;
  }
};

const Feed = () => {
  const [likedPosts, setLikedPosts] = useState<Set<string>>(new Set());
  const [activeFilter, setActiveFilter] = useState<string>("all");
  
  const { data: activities = [], isLoading: isLoadingActivities } = useClubActivity();
  const { data: recentSessions = [] } = useRecentSessions();
  const { data: recentMembers = [] } = useRecentMembers();

  const handleLike = (postId: string) => {
    setLikedPosts(prev => {
      const newSet = new Set(prev);
      if (newSet.has(postId)) {
        newSet.delete(postId);
      } else {
        newSet.add(postId);
      }
      return newSet;
    });
  };

  // Transform database activities into feed format
  const transformActivitiesToFeed = () => {
    const feedItems: any[] = [];

    // Add activities
    activities.forEach(activity => {
      let title = "";
      let content = "";
      let type = activity.type;
      
      switch (activity.type) {
        case "session_created":
          title = "Session Available";
          const sessionVenue = activity.target_session?.Venue || activity.data?.venue;
          content = `Join the upcoming session${sessionVenue ? ` at ${sessionVenue}` : ""}.`;
          break;
        case "session_completed":
          title = "Session Completed";
          content = `Session completed${activity.target_session ? ` at ${activity.target_session.Venue}` : ""}.`;
          break;
        case "session_cancelled":
          title = "Session Cancelled";
          const sessionData = activity.data;
          const registeredCount = sessionData?.registered_count || 0;
          content = `Session scheduled for ${sessionData?.session_venue ? ` ${sessionData.session_venue}` : ''} has been cancelled.${registeredCount > 0 ? ` ${registeredCount} registered players have been notified.` : ''}`;
          break;
        case "member_joined":
          title = "New Member Joined";
          content = `${activity.target_member ? `${activity.target_member.first_name} ${activity.target_member.last_name}` : "A new member"} has joined the club! Welcome to the community.`;
          break;
        case "announcement":
          title = activity.data?.title || "Club Announcement";
          content = activity.data?.message || "New club announcement";
          break;
        case "general":
          title = activity.data?.title || "Club Update";
          content = activity.data?.message || "General club update";
          break;
        case "event":
          title = activity.data?.title || "Club Event";
          content = activity.data?.message || "New club event";
          break;
        case "tournament_result":
          title = activity.data?.title || "Tournament Results";
          content = activity.data?.message || "Tournament results announced";
          break;
        default:
          title = activity.data?.title || "Club Activity";
          content = activity.data?.message || "Club activity update";
      }

      feedItems.push({
        id: activity.id,
        type: activity.type,
        title,
        content,
        author: {
          name: activity.actor_profile ? `${activity.actor_profile.first_name} ${activity.actor_profile.last_name}` : "Session Organizer",
          avatar: activity.actor_profile?.avatar_url || "",
          initials: activity.actor_profile ? `${activity.actor_profile.first_name?.[0] || ""}${activity.actor_profile.last_name?.[0] || ""}` : "SO"
        },
        timestamp: new Date(activity.created_at),
        likes: Math.floor(Math.random() * 20), // Mock likes for now
        comments: Math.floor(Math.random() * 10), // Mock comments for now
        metadata: {
          // Handle session metadata from either target_session (join) or data (direct)
          ...(activity.target_session && {
            date: activity.target_session.Date,
            venue: activity.target_session.Venue
          }),
          ...(activity.type === 'session_created' && activity.data && !activity.target_session && {
            date: activity.data.session_date,
            venue: activity.data.venue
          }),
          ...(activity.target_member && {
            level: activity.target_member.skill_level
          })
        }
      });
    });

    // Add recent sessions as feed items if not already in activities
    recentSessions.forEach(session => {
      const existingActivity = feedItems.find(item => 
        item.type === "session_created" && 
        item.metadata?.date === session.Date
      );
      
      if (!existingActivity) {
        feedItems.push({
          id: `session_${session.id}`,
          type: "session_created",
          title: "Session Available",
          content: `Join the upcoming session at ${session.Venue}.`,
          author: {
            name: "Session Organizer",
            avatar: "",
            initials: "SO"
          },
          timestamp: new Date(session.created_at),
          likes: Math.floor(Math.random() * 10),
          comments: 0,
          metadata: {
            date: session.Date,
            venue: session.Venue,
            participants: Math.floor(Math.random() * 16)
          }
        });
      }
    });

    // Add recent members as feed items if not already in activities
    recentMembers.forEach(member => {
      const existingActivity = feedItems.find(item => 
        item.type === "member_joined" && 
        item.author.name === `${member.user_profiles?.first_name} ${member.user_profiles?.last_name}`
      );
      
      if (!existingActivity && member.user_profiles) {
        feedItems.push({
          id: `member_${member.id}`,
          type: "member_joined",
          title: "New Member Joined",
          content: `${member.user_profiles.first_name} ${member.user_profiles.last_name} has joined the club! Welcome to the community.`,
          author: {
            name: `${member.user_profiles.first_name} ${member.user_profiles.last_name}`,
            avatar: member.user_profiles.avatar_url || "",
            initials: `${member.user_profiles.first_name?.[0] || ""}${member.user_profiles.last_name?.[0] || ""}`
          },
          timestamp: new Date(member.joined_at),
          likes: Math.floor(Math.random() * 15),
          comments: Math.floor(Math.random() * 5),
          metadata: {
            level: member.user_profiles.skill_level
          }
        });
      }
    });

    // Sort by timestamp (most recent first)
    return feedItems.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());
  };

  const feedData = transformActivitiesToFeed();
  
  // Filter feed data based on active filter
  const filteredFeedData = feedData.filter(item => {
    if (activeFilter === "all") return true;
    if (activeFilter === "sessions") return item.type.includes("session");
    if (activeFilter === "members") return item.type === "member_joined";
    if (activeFilter === "tournaments") return item.type === "tournament_result";
    if (activeFilter === "announcements") return item.type === "announcement";
    return true;
  });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-foreground">Activity Feed</h1>
          <p className="text-muted-foreground mt-2">
            Stay updated with club activities and announcements
          </p>
        </div>
        <CreatePostDialog />
      </div>

      {/* Filter Tabs */}
      <div className="flex gap-2 overflow-x-auto pb-2">
        <Button 
          variant={activeFilter === "all" ? "default" : "outline"} 
          size="sm"
          onClick={() => setActiveFilter("all")}
        >
          All
        </Button>
        <Button 
          variant={activeFilter === "sessions" ? "default" : "outline"} 
          size="sm"
          onClick={() => setActiveFilter("sessions")}
        >
          Sessions
        </Button>
        <Button 
          variant={activeFilter === "members" ? "default" : "outline"} 
          size="sm"
          onClick={() => setActiveFilter("members")}
        >
          Members
        </Button>
        <Button 
          variant={activeFilter === "tournaments" ? "default" : "outline"} 
          size="sm"
          onClick={() => setActiveFilter("tournaments")}
        >
          Tournaments
        </Button>
        <Button 
          variant={activeFilter === "announcements" ? "default" : "outline"} 
          size="sm"
          onClick={() => setActiveFilter("announcements")}
        >
          Announcements
        </Button>
      </div>

      {/* Feed Items */}
      <div className="space-y-4">
        {isLoadingActivities ? (
          <Card className="p-8 text-center bg-card border-border">
            <p className="text-muted-foreground">Loading club activities...</p>
          </Card>
        ) : filteredFeedData.length === 0 ? (
          <Card className="p-8 text-center bg-card border-border">
            <p className="text-muted-foreground">No activities to show yet.</p>
          </Card>
        ) : (
          filteredFeedData.map((item) => (
          <Card key={item.id} className="p-6 bg-card border-border">
            <div className="space-y-4">
              {/* Header */}
              <div className="flex items-start justify-between">
                <div className="flex items-center gap-3">
                  <div className="flex-shrink-0">
                    {getActivityIcon(item.type)}
                  </div>
                  <div className="flex items-center gap-3">
                    <Avatar className="h-8 w-8">
                      <AvatarImage src={item.author.avatar} />
                      <AvatarFallback className="text-xs bg-sidebar-accent text-sidebar-accent-foreground">
                        {item.author.initials}
                      </AvatarFallback>
                    </Avatar>
                    <div>
                      <p className="font-medium text-card-foreground text-sm">
                        {item.author.name}
                      </p>
                      <p className="text-xs text-muted-foreground">
                        {formatDistanceToNow(item.timestamp, { addSuffix: true })}
                      </p>
                    </div>
                  </div>
                </div>
                {getActivityBadge(item.type)}
              </div>

              {/* Content */}
              <div className="space-y-3">
                <h3 className="font-semibold text-card-foreground">
                  {item.title}
                </h3>
                <p className="text-muted-foreground">
                  {item.content}
                </p>

                {/* Metadata */}
                {item.metadata && (
                  <div className="flex flex-wrap gap-2 text-sm">
                    {item.metadata.venue && (
                      <span className="text-muted-foreground">📍 {item.metadata.venue}</span>
                    )}
                    {item.metadata.date && (
                      <span className="text-muted-foreground">
                        📅 {format(new Date(item.metadata.date), 'MMM d, yyyy')}
                      </span>
                    )}
                    {item.metadata.level && (
                      <span className="text-muted-foreground">⭐ Level {item.metadata.level}</span>
                    )}
                    {item.metadata.participants && (
                      <span className="text-muted-foreground">👥 {item.metadata.participants} players</span>
                    )}
                    {item.metadata.winners && (
                      <span className="text-muted-foreground">🏆 {item.metadata.winners.join(" & ")}</span>
                    )}
                  </div>
                )}
              </div>

              {/* Actions */}
              <div className="flex items-center gap-4 pt-2 border-t border-border">
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => handleLike(item.id.toString())}
                  className={`flex items-center gap-2 ${
                    likedPosts.has(item.id.toString()) ? 'text-red-500' : 'text-muted-foreground'
                  }`}
                >
                  <Heart 
                    className={`h-4 w-4 ${likedPosts.has(item.id.toString()) ? 'fill-current' : ''}`} 
                  />
                  {item.likes + (likedPosts.has(item.id.toString()) ? 1 : 0)}
                </Button>
                <Button variant="ghost" size="sm" className="flex items-center gap-2 text-muted-foreground">
                  <MessageCircle className="h-4 w-4" />
                  {item.comments}
                </Button>
                <Button variant="ghost" size="sm" className="flex items-center gap-2 text-muted-foreground">
                  <Share2 className="h-4 w-4" />
                  Share
                </Button>
              </div>
            </div>
          </Card>
        )))}
      </div>

      {/* Load More */}
      <div className="text-center">
        <Button variant="outline" className="w-full sm:w-auto">
          Load More Activities
        </Button>
      </div>
    </div>
  );
};

export default Feed;