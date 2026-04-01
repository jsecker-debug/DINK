import { Link } from "react-router-dom";
import { ArrowRight, Users, Calendar, Trophy, Zap, Shield, Star, CheckCircle, Play, Clock, Target } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";

const MarketingHome = () => {
  return (
    <div className="min-h-screen bg-background scroll-smooth">
      {/* Hero Section */}
      <section className="relative overflow-hidden bg-gradient-to-br from-primary/20 via-background to-secondary/20 border-b border-border">
        <div className="absolute inset-0 bg-grid-pattern opacity-10"></div>
        {/* Animated background orbs */}
        <div className="absolute inset-0 overflow-hidden">
          <div className="absolute -top-40 -right-40 w-80 h-80 bg-primary/5 rounded-full blur-3xl animate-pulse"></div>
          <div className="absolute -bottom-40 -left-40 w-80 h-80 bg-secondary/5 rounded-full blur-3xl animate-pulse delay-1000"></div>
        </div>
        <div className="relative max-w-7xl mx-auto px-6 py-24 lg:py-32">
          <div className="text-center">
            <Badge variant="secondary" className="mb-6 hover:scale-105 transition-transform duration-300 cursor-default">
              <Zap className="w-4 h-4 mr-2 animate-pulse" />
              Streamline Your Club Sessions
            </Badge>
            <h1 className="text-5xl lg:text-7xl font-bold text-foreground mb-6 animate-in fade-in-50 slide-in-from-bottom-5 duration-1000">
              Organize Your
              <span className="block text-primary bg-gradient-to-r from-primary to-primary/70 bg-clip-text text-transparent animate-in fade-in-50 slide-in-from-bottom-5 duration-1000 delay-300">
                Club Squad
              </span>
            </h1>
            <p className="text-xl lg:text-2xl text-muted-foreground mb-8 max-w-3xl mx-auto animate-in fade-in-50 slide-in-from-bottom-5 duration-1000 delay-500">
              The ultimate scheduling solution for sports clubs and groups. 
              Generate fair rotations, track scores, and manage your players with ease.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center animate-in fade-in-50 slide-in-from-bottom-5 duration-1000 delay-700">
              <Link to="/signup">
                <Button size="lg" className="text-lg px-8 py-6 bg-primary hover:bg-primary/90 hover:scale-105 transition-all duration-300 hover:shadow-lg hover:shadow-primary/25 group">
                  Get Started Free
                  <ArrowRight className="ml-2 w-5 h-5 group-hover:translate-x-1 transition-transform duration-300" />
                </Button>
              </Link>
              <Link to="/signin">
                <Button size="lg" variant="outline" className="text-lg px-8 py-6 hover:scale-105 transition-all duration-300 hover:shadow-lg hover:bg-accent/50">
                  Sign In
                </Button>
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-24 bg-gradient-to-b from-card/20 to-card/40 border-b border-border relative overflow-hidden">
        {/* Background decoration */}
        <div className="absolute inset-0">
          <div className="absolute top-20 left-20 w-32 h-32 bg-primary/5 rounded-full blur-2xl animate-pulse delay-500"></div>
          <div className="absolute bottom-20 right-20 w-32 h-32 bg-secondary/5 rounded-full blur-2xl animate-pulse delay-1000"></div>
        </div>
        <div className="max-w-7xl mx-auto px-6 relative">
          <div className="text-center mb-16 animate-in fade-in-50 slide-in-from-bottom-5 duration-1000">
            <h2 className="text-4xl font-bold text-foreground mb-4">
              Everything You Need to Run Great Sessions
            </h2>
            <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
              From scheduling to score tracking, we've got every aspect of your club sessions covered.
            </p>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            <Card className="group hover:shadow-2xl hover:shadow-primary/10 hover:scale-[1.02] transition-all duration-500 border-border bg-card/50 hover:bg-card hover:border-primary/20 animate-in fade-in-50 slide-in-from-bottom-5 duration-1000 delay-300">
              <CardHeader className="relative">
                <div className="w-12 h-12 bg-primary/10 rounded-lg flex items-center justify-center mb-4 group-hover:bg-primary/20 group-hover:scale-110 transition-all duration-300">
                  <Users className="w-6 h-6 text-primary group-hover:scale-110 transition-transform duration-300" />
                </div>
                <CardTitle className="group-hover:text-primary transition-colors duration-300">Smart Player Management</CardTitle>
                <CardDescription>
                  Add, organize, and track your players with detailed profiles and skill levels.
                </CardDescription>
              </CardHeader>
              <CardContent>
                <ul className="space-y-2 text-sm text-muted-foreground">
                  <li className="flex items-center gap-2 group-hover:translate-x-1 transition-transform duration-300 delay-75">
                    <CheckCircle className="w-4 h-4 text-green-500 group-hover:scale-110 transition-transform duration-300" />
                    Player profiles with skill ratings
                  </li>
                  <li className="flex items-center gap-2 group-hover:translate-x-1 transition-transform duration-300 delay-100">
                    <CheckCircle className="w-4 h-4 text-green-500 group-hover:scale-110 transition-transform duration-300" />
                    Attendance tracking
                  </li>
                  <li className="flex items-center gap-2 group-hover:translate-x-1 transition-transform duration-300 delay-150">
                    <CheckCircle className="w-4 h-4 text-green-500 group-hover:scale-110 transition-transform duration-300" />
                    Performance history
                  </li>
                </ul>
              </CardContent>
            </Card>

            <Card className="group hover:shadow-2xl hover:shadow-primary/10 hover:scale-[1.02] transition-all duration-500 border-border bg-card/50 hover:bg-card hover:border-primary/20 animate-in fade-in-50 slide-in-from-bottom-5 duration-1000 delay-500">
              <CardHeader className="relative">
                <div className="w-12 h-12 bg-primary/10 rounded-lg flex items-center justify-center mb-4 group-hover:bg-primary/20 group-hover:scale-110 transition-all duration-300">
                  <Calendar className="w-6 h-6 text-primary group-hover:scale-110 transition-transform duration-300" />
                </div>
                <CardTitle className="group-hover:text-primary transition-colors duration-300">Fair Game Rotations</CardTitle>
                <CardDescription>
                  Generate balanced game schedules that ensure everyone gets equal playing time.
                </CardDescription>
              </CardHeader>
              <CardContent>
                <ul className="space-y-2 text-sm text-muted-foreground">
                  <li className="flex items-center gap-2 group-hover:translate-x-1 transition-transform duration-300 delay-75">
                    <CheckCircle className="w-4 h-4 text-green-500 group-hover:scale-110 transition-transform duration-300" />
                    Automatic rotation generation
                  </li>
                  <li className="flex items-center gap-2 group-hover:translate-x-1 transition-transform duration-300 delay-100">
                    <CheckCircle className="w-4 h-4 text-green-500 group-hover:scale-110 transition-transform duration-300" />
                    Skill-based matching
                  </li>
                  <li className="flex items-center gap-2 group-hover:translate-x-1 transition-transform duration-300 delay-150">
                    <CheckCircle className="w-4 h-4 text-green-500 group-hover:scale-110 transition-transform duration-300" />
                    Rest time optimization
                  </li>
                </ul>
              </CardContent>
            </Card>

            <Card className="group hover:shadow-2xl hover:shadow-primary/10 hover:scale-[1.02] transition-all duration-500 border-border bg-card/50 hover:bg-card hover:border-primary/20 animate-in fade-in-50 slide-in-from-bottom-5 duration-1000 delay-700">
              <CardHeader className="relative">
                <div className="w-12 h-12 bg-primary/10 rounded-lg flex items-center justify-center mb-4 group-hover:bg-primary/20 group-hover:scale-110 transition-all duration-300">
                  <Trophy className="w-6 h-6 text-primary group-hover:scale-110 transition-transform duration-300" />
                </div>
                <CardTitle className="group-hover:text-primary transition-colors duration-300">Score Tracking & Rankings</CardTitle>
                <CardDescription>
                  Keep track of game results and maintain player rankings over time.
                </CardDescription>
              </CardHeader>
              <CardContent>
                <ul className="space-y-2 text-sm text-muted-foreground">
                  <li className="flex items-center gap-2 group-hover:translate-x-1 transition-transform duration-300 delay-75">
                    <CheckCircle className="w-4 h-4 text-green-500 group-hover:scale-110 transition-transform duration-300" />
                    Real-time score input
                  </li>
                  <li className="flex items-center gap-2 group-hover:translate-x-1 transition-transform duration-300 delay-100">
                    <CheckCircle className="w-4 h-4 text-green-500 group-hover:scale-110 transition-transform duration-300" />
                    Historical performance data
                  </li>
                  <li className="flex items-center gap-2 group-hover:translate-x-1 transition-transform duration-300 delay-150">
                    <CheckCircle className="w-4 h-4 text-green-500 group-hover:scale-110 transition-transform duration-300" />
                    Leaderboards and rankings
                  </li>
                </ul>
              </CardContent>
            </Card>

            <Card className="group hover:shadow-2xl hover:shadow-primary/10 hover:scale-[1.02] transition-all duration-500 border-border bg-card/50 hover:bg-card hover:border-primary/20 animate-in fade-in-50 slide-in-from-bottom-5 duration-1000 delay-300">
              <CardHeader className="relative">
                <div className="w-12 h-12 bg-primary/10 rounded-lg flex items-center justify-center mb-4 group-hover:bg-primary/20 group-hover:scale-110 transition-all duration-300">
                  <Clock className="w-6 h-6 text-primary group-hover:scale-110 transition-transform duration-300" />
                </div>
                <CardTitle className="group-hover:text-primary transition-colors duration-300">Session Management</CardTitle>
                <CardDescription>
                  Create and manage multiple sessions with different formats and rules.
                </CardDescription>
              </CardHeader>
              <CardContent>
                <ul className="space-y-2 text-sm text-muted-foreground">
                  <li className="flex items-center gap-2 group-hover:translate-x-1 transition-transform duration-300 delay-75">
                    <CheckCircle className="w-4 h-4 text-green-500 group-hover:scale-110 transition-transform duration-300" />
                    Multiple session types
                  </li>
                  <li className="flex items-center gap-2 group-hover:translate-x-1 transition-transform duration-300 delay-100">
                    <CheckCircle className="w-4 h-4 text-green-500 group-hover:scale-110 transition-transform duration-300" />
                    Field assignment
                  </li>
                  <li className="flex items-center gap-2 group-hover:translate-x-1 transition-transform duration-300 delay-150">
                    <CheckCircle className="w-4 h-4 text-green-500 group-hover:scale-110 transition-transform duration-300" />
                    Time slot management
                  </li>
                </ul>
              </CardContent>
            </Card>

            <Card className="group hover:shadow-2xl hover:shadow-primary/10 hover:scale-[1.02] transition-all duration-500 border-border bg-card/50 hover:bg-card hover:border-primary/20 animate-in fade-in-50 slide-in-from-bottom-5 duration-1000 delay-500">
              <CardHeader className="relative">
                <div className="w-12 h-12 bg-primary/10 rounded-lg flex items-center justify-center mb-4 group-hover:bg-primary/20 group-hover:scale-110 transition-all duration-300">
                  <Target className="w-6 h-6 text-primary group-hover:scale-110 transition-transform duration-300" />
                </div>
                <CardTitle className="group-hover:text-primary transition-colors duration-300">Drag & Drop Interface</CardTitle>
                <CardDescription>
                  Intuitive visual interface for managing players and field assignments.
                </CardDescription>
              </CardHeader>
              <CardContent>
                <ul className="space-y-2 text-sm text-muted-foreground">
                  <li className="flex items-center gap-2 group-hover:translate-x-1 transition-transform duration-300 delay-75">
                    <CheckCircle className="w-4 h-4 text-green-500 group-hover:scale-110 transition-transform duration-300" />
                    Visual field layout
                  </li>
                  <li className="flex items-center gap-2 group-hover:translate-x-1 transition-transform duration-300 delay-100">
                    <CheckCircle className="w-4 h-4 text-green-500 group-hover:scale-110 transition-transform duration-300" />
                    Drag and drop players
                  </li>
                  <li className="flex items-center gap-2 group-hover:translate-x-1 transition-transform duration-300 delay-150">
                    <CheckCircle className="w-4 h-4 text-green-500 group-hover:scale-110 transition-transform duration-300" />
                    Real-time updates
                  </li>
                </ul>
              </CardContent>
            </Card>

            <Card className="group hover:shadow-2xl hover:shadow-primary/10 hover:scale-[1.02] transition-all duration-500 border-border bg-card/50 hover:bg-card hover:border-primary/20 animate-in fade-in-50 slide-in-from-bottom-5 duration-1000 delay-700">
              <CardHeader className="relative">
                <div className="w-12 h-12 bg-primary/10 rounded-lg flex items-center justify-center mb-4 group-hover:bg-primary/20 group-hover:scale-110 transition-all duration-300">
                  <Shield className="w-6 h-6 text-primary group-hover:scale-110 transition-transform duration-300" />
                </div>
                <CardTitle className="group-hover:text-primary transition-colors duration-300">Club Management</CardTitle>
                <CardDescription>
                  Manage multiple clubs and groups with separate member lists and settings.
                </CardDescription>
              </CardHeader>
              <CardContent>
                <ul className="space-y-2 text-sm text-muted-foreground">
                  <li className="flex items-center gap-2 group-hover:translate-x-1 transition-transform duration-300 delay-75">
                    <CheckCircle className="w-4 h-4 text-green-500 group-hover:scale-110 transition-transform duration-300" />
                    Multi-club support
                  </li>
                  <li className="flex items-center gap-2 group-hover:translate-x-1 transition-transform duration-300 delay-100">
                    <CheckCircle className="w-4 h-4 text-green-500 group-hover:scale-110 transition-transform duration-300" />
                    Member permissions
                  </li>
                  <li className="flex items-center gap-2 group-hover:translate-x-1 transition-transform duration-300 delay-150">
                    <CheckCircle className="w-4 h-4 text-green-500 group-hover:scale-110 transition-transform duration-300" />
                    Club-specific settings
                  </li>
                </ul>
              </CardContent>
            </Card>
          </div>
        </div>
      </section>

      {/* How It Works Section */}
      <section className="py-24 bg-background border-b border-border relative overflow-hidden">
        {/* Background decoration */}
        <div className="absolute inset-0">
          <div className="absolute top-32 left-1/4 w-24 h-24 bg-primary/3 rounded-full blur-xl animate-pulse delay-700"></div>
          <div className="absolute bottom-32 right-1/4 w-24 h-24 bg-secondary/3 rounded-full blur-xl animate-pulse delay-1500"></div>
        </div>
        <div className="max-w-7xl mx-auto px-6 relative">
          <div className="text-center mb-16 animate-in fade-in-50 slide-in-from-bottom-5 duration-1000">
            <h2 className="text-4xl font-bold text-foreground mb-4">
              Get Started in Minutes
            </h2>
            <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
              Our simple 3-step process gets you up and running with your first session.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div className="text-center group hover:scale-105 transition-all duration-500 animate-in fade-in-50 slide-in-from-bottom-5 duration-1000 delay-300">
              <div className="w-16 h-16 bg-primary text-primary-foreground rounded-full flex items-center justify-center text-2xl font-bold mx-auto mb-6 group-hover:scale-110 group-hover:shadow-lg group-hover:shadow-primary/25 transition-all duration-300 animate-pulse">
                1
              </div>
              <h3 className="text-xl font-semibold mb-4 group-hover:text-primary transition-colors duration-300">Create Your Club</h3>
              <p className="text-muted-foreground group-hover:text-foreground transition-colors duration-300">
                Set up your club profile and add your first players to get started.
              </p>
            </div>

            <div className="text-center group hover:scale-105 transition-all duration-500 animate-in fade-in-50 slide-in-from-bottom-5 duration-1000 delay-500">
              <div className="w-16 h-16 bg-primary text-primary-foreground rounded-full flex items-center justify-center text-2xl font-bold mx-auto mb-6 group-hover:scale-110 group-hover:shadow-lg group-hover:shadow-primary/25 transition-all duration-300 animate-pulse delay-300">
                2
              </div>
              <h3 className="text-xl font-semibold mb-4 group-hover:text-primary transition-colors duration-300">Schedule a Session</h3>
              <p className="text-muted-foreground group-hover:text-foreground transition-colors duration-300">
                Create a new session, set the date, and choose your players.
              </p>
            </div>

            <div className="text-center group hover:scale-105 transition-all duration-500 animate-in fade-in-50 slide-in-from-bottom-5 duration-1000 delay-700">
              <div className="w-16 h-16 bg-primary text-primary-foreground rounded-full flex items-center justify-center text-2xl font-bold mx-auto mb-6 group-hover:scale-110 group-hover:shadow-lg group-hover:shadow-primary/25 transition-all duration-300 animate-pulse delay-600">
                3
              </div>
              <h3 className="text-xl font-semibold mb-4 group-hover:text-primary transition-colors duration-300">Generate & Play</h3>
              <p className="text-muted-foreground group-hover:text-foreground transition-colors duration-300">
                Generate fair rotations and start playing with organized games.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Testimonials Section */}
      <section className="py-24 bg-gradient-to-b from-card/20 to-card/40 border-b border-border relative overflow-hidden">
        {/* Background decoration */}
        <div className="absolute inset-0">
          <div className="absolute top-16 right-16 w-40 h-40 bg-primary/3 rounded-full blur-2xl animate-pulse delay-1000"></div>
          <div className="absolute bottom-16 left-16 w-40 h-40 bg-secondary/3 rounded-full blur-2xl animate-pulse delay-2000"></div>
        </div>
        <div className="max-w-7xl mx-auto px-6 relative">
          <div className="text-center mb-16 animate-in fade-in-50 slide-in-from-bottom-5 duration-1000">
            <h2 className="text-4xl font-bold text-foreground mb-4">
              Loved by Sports Clubs Everywhere
            </h2>
            <p className="text-xl text-muted-foreground">
              See what club organizers are saying about our platform.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <Card className="border-border hover:shadow-2xl hover:shadow-primary/10 hover:scale-105 transition-all duration-500 bg-card/50 hover:bg-card group animate-in fade-in-50 slide-in-from-bottom-5 duration-1000 delay-300">
              <CardContent className="pt-6">
                <div className="flex items-center mb-4">
                  {[...Array(5)].map((_, i) => (
                    <Star key={i} className="w-5 h-5 text-yellow-400 fill-current group-hover:scale-110 transition-transform duration-300" style={{transitionDelay: `${i * 50}ms`}} />
                  ))}
                </div>
                <p className="text-muted-foreground mb-4 group-hover:text-foreground transition-colors duration-300">
                  "This app has completely transformed how we run our club sessions. 
                  The automatic rotation generation saves us so much time!"
                </p>
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-primary/20 rounded-full flex items-center justify-center group-hover:bg-primary/30 group-hover:scale-110 transition-all duration-300">
                    <Users className="w-5 h-5 text-primary" />
                  </div>
                  <div>
                    <p className="font-semibold group-hover:text-primary transition-colors duration-300">Sarah Johnson</p>
                    <p className="text-sm text-muted-foreground">Club Organizer</p>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card className="border-border hover:shadow-2xl hover:shadow-primary/10 hover:scale-105 transition-all duration-500 bg-card/50 hover:bg-card group animate-in fade-in-50 slide-in-from-bottom-5 duration-1000 delay-500">
              <CardContent className="pt-6">
                <div className="flex items-center mb-4">
                  {[...Array(5)].map((_, i) => (
                    <Star key={i} className="w-5 h-5 text-yellow-400 fill-current group-hover:scale-110 transition-transform duration-300" style={{transitionDelay: `${i * 50}ms`}} />
                  ))}
                </div>
                <p className="text-muted-foreground mb-4 group-hover:text-foreground transition-colors duration-300">
                  "The drag and drop interface is so intuitive. Our players love 
                  being able to see their field assignments clearly."
                </p>
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-primary/20 rounded-full flex items-center justify-center group-hover:bg-primary/30 group-hover:scale-110 transition-all duration-300">
                    <Play className="w-5 h-5 text-primary" />
                  </div>
                  <div>
                    <p className="font-semibold group-hover:text-primary transition-colors duration-300">Mike Chen</p>
                    <p className="text-sm text-muted-foreground">Tournament Director</p>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card className="border-border hover:shadow-2xl hover:shadow-primary/10 hover:scale-105 transition-all duration-500 bg-card/50 hover:bg-card group animate-in fade-in-50 slide-in-from-bottom-5 duration-1000 delay-700">
              <CardContent className="pt-6">
                <div className="flex items-center mb-4">
                  {[...Array(5)].map((_, i) => (
                    <Star key={i} className="w-5 h-5 text-yellow-400 fill-current group-hover:scale-110 transition-transform duration-300" style={{transitionDelay: `${i * 50}ms`}} />
                  ))}
                </div>
                <p className="text-muted-foreground mb-4 group-hover:text-foreground transition-colors duration-300">
                  "Finally, a solution that handles all the complexity of managing 
                  multiple fields and players. It's been a game-changer!"
                </p>
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-primary/20 rounded-full flex items-center justify-center group-hover:bg-primary/30 group-hover:scale-110 transition-all duration-300">
                    <Trophy className="w-5 h-5 text-primary" />
                  </div>
                  <div>
                    <p className="font-semibold group-hover:text-primary transition-colors duration-300">Lisa Rodriguez</p>
                    <p className="text-sm text-muted-foreground">League Coordinator</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-24 bg-gradient-to-r from-primary/20 to-secondary/20 border-b border-border relative overflow-hidden">
        {/* Enhanced background decoration */}
        <div className="absolute inset-0">
          <div className="absolute -top-20 -left-20 w-64 h-64 bg-primary/10 rounded-full blur-3xl animate-pulse"></div>
          <div className="absolute -bottom-20 -right-20 w-64 h-64 bg-secondary/10 rounded-full blur-3xl animate-pulse delay-1000"></div>
          <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-32 h-32 bg-primary/5 rounded-full blur-2xl animate-pulse delay-500"></div>
        </div>
        <div className="max-w-4xl mx-auto px-6 text-center relative">
          <h2 className="text-4xl font-bold text-foreground mb-6 animate-in fade-in-50 slide-in-from-bottom-5 duration-1000">
            Ready to Transform Your Club Sessions?
          </h2>
          <p className="text-xl text-muted-foreground mb-8 animate-in fade-in-50 slide-in-from-bottom-5 duration-1000 delay-300">
            Join thousands of clubs already using our platform to organize better games.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center animate-in fade-in-50 slide-in-from-bottom-5 duration-1000 delay-500">
            <Link to="/signup">
              <Button size="lg" className="text-lg px-8 py-6 bg-primary hover:bg-primary/90 hover:scale-110 transition-all duration-300 hover:shadow-2xl hover:shadow-primary/25 group">
                Start Free Trial
                <ArrowRight className="ml-2 w-5 h-5 group-hover:translate-x-2 transition-transform duration-300" />
              </Button>
            </Link>
            <Link to="/signin">
              <Button size="lg" variant="outline" className="text-lg px-8 py-6 hover:scale-110 transition-all duration-300 hover:shadow-xl hover:bg-accent/50 hover:border-primary/50">
                Sign In to Existing Account
              </Button>
            </Link>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-12 bg-card border-t border-border relative overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-t from-primary/5 to-transparent"></div>
        <div className="max-w-7xl mx-auto px-6 relative">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-8 animate-in fade-in-50 slide-in-from-bottom-5 duration-1000">
            <div className="group">
              <h3 className="text-lg font-semibold mb-4 group-hover:text-primary transition-colors duration-300">Club Squad Scheduler</h3>
              <p className="text-muted-foreground group-hover:text-foreground transition-colors duration-300">
                The ultimate solution for organizing club sessions and managing your team.
              </p>
            </div>
            <div className="group">
              <h4 className="font-semibold mb-4 group-hover:text-primary transition-colors duration-300">Product</h4>
              <ul className="space-y-2 text-muted-foreground">
                <li><Link to="/signup" className="hover:text-primary hover:translate-x-1 transition-all duration-300 inline-block">Sign Up</Link></li>
                <li><Link to="/signin" className="hover:text-primary hover:translate-x-1 transition-all duration-300 inline-block">Sign In</Link></li>
                <li><a href="#" className="hover:text-primary hover:translate-x-1 transition-all duration-300 inline-block">Features</a></li>
                <li><a href="#" className="hover:text-primary hover:translate-x-1 transition-all duration-300 inline-block">Pricing</a></li>
              </ul>
            </div>
            <div className="group">
              <h4 className="font-semibold mb-4 group-hover:text-primary transition-colors duration-300">Support</h4>
              <ul className="space-y-2 text-muted-foreground">
                <li><a href="#" className="hover:text-primary hover:translate-x-1 transition-all duration-300 inline-block">Help Center</a></li>
                <li><a href="#" className="hover:text-primary hover:translate-x-1 transition-all duration-300 inline-block">Contact Us</a></li>
                <li><a href="#" className="hover:text-primary hover:translate-x-1 transition-all duration-300 inline-block">Documentation</a></li>
              </ul>
            </div>
            <div className="group">
              <h4 className="font-semibold mb-4 group-hover:text-primary transition-colors duration-300">Legal</h4>
              <ul className="space-y-2 text-muted-foreground">
                <li><a href="#" className="hover:text-primary hover:translate-x-1 transition-all duration-300 inline-block">Privacy Policy</a></li>
                <li><a href="#" className="hover:text-primary hover:translate-x-1 transition-all duration-300 inline-block">Terms of Service</a></li>
                <li><a href="#" className="hover:text-primary hover:translate-x-1 transition-all duration-300 inline-block">Cookie Policy</a></li>
              </ul>
            </div>
          </div>
          <Separator className="my-8 animate-in fade-in-50 duration-1000 delay-300" />
          <div className="text-center text-muted-foreground animate-in fade-in-50 duration-1000 delay-500">
            <p className="hover:text-foreground transition-colors duration-300">&copy; 2024 Club Squad Scheduler. All rights reserved.</p>
          </div>
        </div>
      </footer>
    </div>
  );
};

export default MarketingHome; 