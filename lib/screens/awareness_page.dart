import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import 'signin_screen.dart';

class AwarenessPage extends StatefulWidget {
  @override
  State<AwarenessPage> createState() => _AwarenessPageState();
}

class _AwarenessPageState extends State<AwarenessPage> {
  // Initialize AuthService to handle sign out
  final AuthService _authService = AuthService();
  
  // Track sign out loading state
  bool isSigningOut = false;

  /// List of empowerment articles and resources
  /// Each article contains title, author, description, icon, and link to full article
  final List<Map<String, String>> articles = [
    {
      'title': 'Breaking the Glass Ceiling: Women in Leadership',
      'author': 'Forbes',
      'description': 'Discover how women are breaking barriers and leading organizations globally',
      'icon': '👩‍💼',
      'link': 'https://www.forbes.com/women-in-leadership',
    },
    {
      'title': 'Financial Independence for Women',
      'author': 'Harvard Business Review',
      'description': 'Essential strategies for women to achieve economic empowerment',
      'icon': '💰',
      'link': 'https://www.hbr.org/women-financial-independence',
    },
    {
      'title': 'Ending Gender-Based Violence',
      'author': 'UN Women',
      'description': 'Understanding GBV and how to support survivors and create change',
      'icon': '🤝',
      'link': 'https://www.unwomen.org/gbv',
    },
    {
      'title': 'Women Entrepreneurs: Starting Your Business',
      'author': 'World Bank',
      'description': 'Complete guide for women starting and growing their own businesses',
      'icon': '🚀',
      'link': 'https://www.worldbank.org/women-entrepreneurs',
    },
    {
      'title': 'Mental Health & Women\'s Wellness',
      'author': 'Psychology Today',
      'description': 'Resources for mental health support and self-care for women',
      'icon': '🧠',
      'link': 'https://www.psychologytoday.com/women-wellness',
    },
    {
      'title': 'Education: The Path to Empowerment',
      'author': 'UNESCO',
      'description': 'Why education is crucial for women\'s empowerment worldwide',
      'icon': '📚',
      'link': 'https://www.unesco.org/women-education',
    },
    {
      'title': 'Workplace Rights & Harassment Prevention',
      'author': 'ILO',
      'description': 'Know your rights and resources for workplace safety',
      'icon': '⚖️',
      'link': 'https://www.ilo.org/workplace-rights',
    },
    {
      'title': 'Health & Reproductive Rights',
      'author': 'WHO',
      'description': 'Comprehensive information on women\'s health and reproductive choices',
      'icon': '❤️',
      'link': 'https://www.who.org/womens-health',
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

  /// Build individual article card widget
  /// Creates a clickable card for each empowerment article
  Widget _buildArticleCard(Map<String, String> article) {
    return Card(
      elevation: 3, // Shadow depth
      margin: EdgeInsets.symmetric(vertical: 12),
      child: InkWell(
        onTap: () => _launchURL(article['link']!), // Open article link on tap
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Article category emoji icon
                  Text(
                    article['icon']!,
                    style: TextStyle(fontSize: 32),
                  ),
                  SizedBox(width: 12),
                  // Title and author section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Article title
                        Text(
                          article['title']!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        // Author/source attribution
                        Text(
                          'By ${article['author']!}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // External link icon to indicate clickable
                  Icon(Icons.open_in_new, size: 20, color: Colors.blue),
                ],
              ),
              SizedBox(height: 12),
              // Article description/summary
              Text(
                article['description']!,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.5, // Line height for better readability
                ),
                maxLines: 3,
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
        title: Text("AWARENESS"),
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
      // Main content - scrollable list of articles
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Page title
          Text(
            'Empower Yourself',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          // Page subtitle
          Text(
            'Read articles and resources that empower women globally',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 20),
          // Generate article cards dynamically from list
          ...articles.map((article) {
            return _buildArticleCard(article);
          }).toList(),
          SizedBox(height: 16),
          // Helpful tip container
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple[50], // Light purple background
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.purple, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tap any article to read the full content and learn more',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.purple[800],
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