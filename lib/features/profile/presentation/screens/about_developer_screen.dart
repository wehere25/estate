import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '/core/constants/app_colors.dart';

class AboutDeveloperScreen extends StatelessWidget {
  const AboutDeveloperScreen({Key? key}) : super(key: key);

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Developer'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section with Background
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.lightColorScheme.primary,
                    AppColors.lightColorScheme.primaryContainer,
                  ],
                ),
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Profile Image
                  Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        'https://avatars.githubusercontent.com/u/HASHIM-HAMEEM',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.person,
                              size: 60,
                              color: AppColors.lightColorScheme.primary,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Developer Name
                  const Text(
                    'Hashim Hameem',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Title
                  const Text(
                    'Full-Stack Developer & Security Engineer',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Bio Section
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Biography',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.lightColorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Hailing from the beautiful valleys of Kashmir, I am a young, ambitious developer with a passion for creating innovative digital solutions. My expertise spans the entire development ecosystem.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Technical Skills Section
                  Text(
                    'Technical Skills',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.lightColorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Skill Cards
                  _buildSkillsList(),

                  const SizedBox(height: 24),

                  // Approach Section
                  Text(
                    'My Approach',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.lightColorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'I approach each project with creativity, technical precision, and a commitment to excellence. My goal is to deliver solutions that not only meet technical requirements but exceed user expectations.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const Text(
                    '\nLet\'s build something amazing together.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Contact Section
                  Text(
                    'Connect With Me',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.lightColorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildContactItem(
                    context,
                    Icons.email,
                    'Email',
                    'hashimdar141@gmail.com',
                    'mailto:hashimdar141@gmail.com',
                  ),
                  const SizedBox(height: 12),
                  _buildContactItem(
                    context,
                    Icons.code,
                    'GitHub',
                    'github.com/HASHIM-HAMEEM',
                    'https://github.com/HASHIM-HAMEEM',
                  ),
                  const SizedBox(height: 12),
                  _buildContactItem(
                    context,
                    Icons.public,
                    'Twitter',
                    'x.com/HashimScnz',
                    'https://x.com/HashimScnz',
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              width: double.infinity,
              color: Colors.grey.shade100,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Text(
                    '© ${DateTime.now().year} Hashim Hameem',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'All Rights Reserved',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsList() {
    final skills = [
      {
        'title': 'Mobile Development',
        'description':
            'Building intuitive and responsive applications for iOS and Android',
        'icon': Icons.smartphone,
        'color': Colors.blue,
      },
      {
        'title': 'Web Development',
        'description':
            'Crafting engaging, user-friendly websites with modern frameworks',
        'icon': Icons.web,
        'color': Colors.green,
      },
      {
        'title': 'Full-Stack Development',
        'description':
            'Seamlessly integrating front-end and back-end technologies',
        'icon': Icons.code,
        'color': Colors.purple,
      },
      {
        'title': 'Cloud Engineering',
        'description': 'Implementing scalable, resilient cloud infrastructure',
        'icon': Icons.cloud,
        'color': Colors.orange,
      },
      {
        'title': 'DevOps',
        'description':
            'Automating workflows and optimizing development pipelines',
        'icon': Icons.settings,
        'color': Colors.red,
      },
      {
        'title': 'Network Security',
        'description':
            'Protecting digital assets through robust security implementations',
        'icon': Icons.security,
        'color': Colors.teal,
      },
    ];

    return Column(
      children: skills
          .map((skill) => _buildSkillCard(
                title: skill['title'] as String,
                description: skill['description'] as String,
                icon: skill['icon'] as IconData,
                color: skill['color'] as Color,
              ))
          .toList(),
    );
  }

  Widget _buildSkillCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context,
    IconData icon,
    String title,
    String value,
    String url,
  ) {
    return GestureDetector(
      onTap: () async {
        final Uri uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Could not launch $url'),
              ),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.lightColorScheme.primary),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.lightColorScheme.primary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
