import { supabase } from './supabase';

export interface InviteEmailData {
  recipientEmail: string;
  recipientName?: string;
  clubName: string;
  inviterName: string;
  inviteUrl: string;
  personalMessage?: string;
}

export const generateInviteToken = (): string => {
  return crypto.randomUUID() + '-' + Date.now().toString(36);
};


export const sendInviteEmail = async (data: InviteEmailData): Promise<{ success: boolean; messageId?: string; error?: string }> => {
  try {
    // Get the current session to ensure we have proper auth
    const { data: { session } } = await supabase.auth.getSession();
    
    if (!session) {
      return { success: false, error: 'User not authenticated' };
    }

    const { data: result, error } = await supabase.functions.invoke('send-invite-email', {
      body: {
        recipientEmail: data.recipientEmail,
        recipientName: data.recipientName,
        clubName: data.clubName,
        inviterName: data.inviterName,
        inviteUrl: data.inviteUrl,
        personalMessage: data.personalMessage
      },
      headers: {
        Authorization: `Bearer ${session.access_token}`,
      }
    });

    if (error) {
      console.error('Edge Function error:', error);
      
      // Provide more specific error messages
      if (error.message.includes('RESEND_API_KEY not configured')) {
        return { success: false, error: 'Email service not configured. Please contact support.' };
      }
      
      return { success: false, error: `Email service error: ${error.message}` };
    }

    if (!result) {
      return { success: false, error: 'No response from email service' };
    }

    if (!result.success) {
      console.error('Email sending failed:', result.error);
      return { success: false, error: result.error || 'Failed to send email' };
    }

    return { success: true, messageId: result.messageId };
  } catch (error) {
    console.error('Error sending invite email:', error);
    return { 
      success: false, 
      error: error instanceof Error ? error.message : 'Unknown error occurred' 
    };
  }
};

export const getInviteUrl = (token: string): string => {
  const baseUrl = window.location.origin;
  return `${baseUrl}/signup?invite=${token}`;
};