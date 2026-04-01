import { useState } from 'react'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger, DialogDescription } from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Label } from "@/components/ui/label"
import { PlusIcon, Mail, Send } from "lucide-react"
import { supabase } from "@/lib/supabase"
import { toast } from "sonner"
import { useQueryClient } from "@tanstack/react-query"
import { useClub } from "@/contexts/ClubContext"
import { useAuth } from "@/contexts/AuthContext"
import { generateInviteToken, sendInviteEmail, getInviteUrl } from "@/lib/email"

export function AddParticipantDialog() {
  const [isOpen, setIsOpen] = useState(false)
  const [loading, setLoading] = useState(false)
  const queryClient = useQueryClient()
  const { selectedClubId, selectedClub } = useClub()
  const { user } = useAuth()
  const [formData, setFormData] = useState({
    email: '',
    message: ''
  })

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target
    setFormData(prev => ({
      ...prev,
      [name]: value
    }))
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)

    try {
      if (!selectedClubId || !selectedClub) {
        throw new Error('No club selected')
      }

      if (!formData.email) {
        throw new Error('Email is required')
      }

      if (!user) {
        throw new Error('You must be logged in to send invitations')
      }

      // Generate unique invite token
      const token = generateInviteToken()
      const inviteUrl = getInviteUrl(token)

      // Create invitation record in database
      const { error: inviteError } = await supabase
        .from('club_invitations')
        .insert([{
          club_id: selectedClubId,
          invited_by: user.id,
          email: formData.email,
          token: token,
          personal_message: formData.message || null,
          status: 'pending'
        }])

      if (inviteError) {
        console.error('Database error:', inviteError)
        throw new Error('Failed to create invitation record')
      }

      // Send email invitation
      const inviterName = user.user_metadata?.full_name || user.email || 'A club admin'
      
      const emailResult = await sendInviteEmail({
        recipientEmail: formData.email,
        clubName: selectedClub.name,
        inviterName: inviterName,
        inviteUrl: inviteUrl,
        personalMessage: formData.message || undefined
      })

      if (!emailResult.success) {
        // If email fails, we should clean up the database record
        // Note: This might fail due to RLS policies, but we'll ignore that error
        try {
          await supabase
            .from('club_invitations')
            .delete()
            .eq('token', token)
        } catch (cleanupError) {
          console.log('Could not cleanup invitation record:', cleanupError)
          // Ignore cleanup errors - the record will expire naturally
        }
        
        throw new Error(`Failed to send email: ${emailResult.error}`)
      }

      toast.success(`Invitation sent successfully to ${formData.email}!`)

      // Reset form and close dialog
      setFormData({
        email: '',
        message: ''
      })
      setIsOpen(false)

      // Refresh any related queries
      queryClient.invalidateQueries({ queryKey: ["club-members", selectedClubId] })
      queryClient.invalidateQueries({ queryKey: ["club-invitations", selectedClubId] })
    } catch (error) {
      console.error('Error sending invitation:', error)
      toast.error(error instanceof Error ? error.message : 'An error occurred while sending the invitation')
    } finally {
      setLoading(false)
    }
  }

  return (
    <Dialog open={isOpen} onOpenChange={setIsOpen}>
      <DialogTrigger asChild>
        <Button className="w-full">
          <Mail className="mr-2 h-4 w-4" />
          Invite Member
        </Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Invite New Member</DialogTitle>
          <DialogDescription>
            Send an email invitation to join {selectedClub?.name}. They'll receive a link to automatically join the club.
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4 pt-4">
          <div className="space-y-2">
            <Label htmlFor="email">Email Address</Label>
            <Input
              id="email"
              name="email"
              type="email"
              required
              value={formData.email}
              onChange={handleChange}
              placeholder="member@example.com"
              className="bg-background border-input"
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="message">Personal Message (Optional)</Label>
            <Textarea
              id="message"
              name="message"
              rows={3}
              value={formData.message}
              onChange={handleChange}
              placeholder="Add a personal message to the invitation..."
              className="bg-background border-input"
            />
          </div>

          <Button
            type="submit"
            disabled={loading}
            className="w-full"
          >
            {loading ? (
              <>
                <Send className="mr-2 h-4 w-4 animate-spin" />
                Sending...
              </>
            ) : (
              <>
                <Send className="mr-2 h-4 w-4" />
                Send Invitation
              </>
            )}
          </Button>
        </form>
      </DialogContent>
    </Dialog>
  )
} 