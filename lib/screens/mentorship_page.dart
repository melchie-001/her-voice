import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import 'signin_screen.dart';

class MentorshipPage extends StatefulWidget {
  @override
  State<MentorshipPage> createState() => _MentorshipPageState();
}

class _MentorshipPageState extends State<MentorshipPage> {
  // Initialize AuthService to handle sign out
  final AuthService _authService = AuthService();
  
  // Track sign out loading state
  bool isSigningOut = false;

  /// List of mentorship resources with platform links
  /// Each resource contains title, description, platform, icon, and clickable link
  final List<Map<String, String>> mentorshipResources = [
    {
      'title': 'Women in Tech WhatsApp Community',
      'description': 'Join a community of female tech professionals and mentors',
      'platform': 'WhatsApp',
      'icon': '💬',
      'link': 'https://chat.whatsapp.com/example1',
    },
    {
      'title': 'Female Founders LinkedIn Group',
      'description': 'Connect with women entrepreneurs and business mentors',
      'platform': 'LinkedIn',
      'icon': '💼',
      'link': 'https://www.linkedin.com/groups/example1',
    },
    {
      'title': 'Women Empowerment Instagram',
      'description': 'Follow inspiring women leaders and mentors',
      'platform': 'Instagram',
      'icon': '📸',
      'link': 'https://www.instagram.com/example1',
    },
    {
      'title': 'Professional Women WhatsApp Channel',
      'description': 'Access mentoring resources and networking opportunities',
      'platform': 'WhatsApp',
      'icon': '💬',
      'link': 'https://chat.whatsapp.com/example2',
    },
    {
      'title': 'Women Leaders LinkedIn',
      'description': 'Network with C-suite women and industry leaders',
      'platform': 'LinkedIn',
      'icon': '💼',
      'link': 'https://www.linkedin.com/groups/example2',
    },
    {
      'title': 'Mentorship Programs Instagram',
      'description': 'Discover mentorship opportunities and success stories',
      'platform': 'Instagram',
      'icon': '📸',
      'link': 'https://www.instagram.com/example2',
    },
  ];

  /// Handle sign out with confirmation dialog
  /// Shows alert asking user to confirm before signing out
  void _handleSignOut() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sign Out'),
          content: Text('Are you sure you want to sign out?'),
          actions: [
            // Cancel button - dismiss dialog
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            // Sign out button - perform logout and navigate to signin
            TextButton(
              child: Text('Sign Out'),
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                
                setState(() {
                  isSigningOut = true; // Show loading spinner
                });

                try {
                  // Call AuthService to sign out user
                  await _authService.signOut();

                  // Navigate to SignInScreen and remove all previous routes
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => SignInScreen()),
                  );

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Signed out successfully')),
                  );
                } catch (e) {
                  setState(() {
                    isSigningOut = false; // Hide loading spinner
                  });
                  // Show error message if sign out fails
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error signing out')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  /// Launch URL in external browser
  /// Takes a URL string and opens it using the url_launcher package
  void _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      // Show error if URL cannot be opened
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open link')),
      );
    }
  }

  /// Get platform-specific color for badge styling
  /// Returns appropriate color based on social media platform
  Color _getPlatformColor(String platform) {
    switch (platform) {
      case 'WhatsApp':
        return Colors.green; // WhatsApp green
      case 'LinkedIn':
        return Colors.blue; // LinkedIn blue
      case 'Instagram':
        return Colors.pink; // Instagram pink
      default:
        return Colors.grey;
    }
  }

  /// Build individual resource card widget
  /// Creates a clickable card for each mentorship resource
  Widget _buildResourceCard(Map<String, String> resource) {
    return Card(
      elevation: 3, // Shadow depth
      margin: EdgeInsets.symmetric(vertical: 12),
      child: InkWell(
        onTap: () => _launchURL(resource['link']!), // Open link on tap
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Platform emoji icon
                  Text(
                    resource['icon']!,
                    style: TextStyle(fontSize: 28),
                  ),
                  SizedBox(width: 12),
                  // Title and platform badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Resource title
                        Text(
                          resource['title']!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        // Platform badge with color coding
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getPlatformColor(resource['platform']!)
                                .withOpacity(0.2), // Subtle background
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            resource['platform']!,
                            style: TextStyle(
                              fontSize: 11,
                              color: _getPlatformColor(resource['platform']!),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Arrow icon to indicate clickable
                  Icon(Icons.arrow_forward, color: Colors.grey),
                ],
              ),
              SizedBox(height: 12),
              // Resource description
              Text(
                resource['description']!,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("MENTORSHIP"),
        actions: [
          // Show spinner or logout icon based on signing out state
          isSigningOut
              ? Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(Icons.logout),
                  onPressed: _handleSignOut,
                  tooltip: 'Sign Out',
                ),
        ],
      ),
      // Main content - scrollable list of resources
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Page title
          Text(
            'Find Your Mentor',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          // Page subtitle
          Text(
            'Connect with inspiring women mentors across various platforms',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 20),
          // Generate resource cards dynamically from list
          ...mentorshipResources.map((resource) {
            return _buildResourceCard(resource);
          }).toList(),
          SizedBox(height: 16),
          // Helpful tip container
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50], // Light blue background
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tap any card to visit the community or group directly',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}