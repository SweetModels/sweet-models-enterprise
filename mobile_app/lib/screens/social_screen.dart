import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pantalla Social - Feed de modelos
/// Diseño enterprise minimalista usando Shadcn UI Zinc palette
class SocialScreen extends StatefulWidget {
  const SocialScreen({Key? key}) : super(key: key);

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final List<ModelPost> _posts = [
    ModelPost(
      modelName: 'Sophie Anderson',
      modelImage: '💎',
      location: 'Paris, France',
      verified: true,
      likes: 2847,
      comments: 142,
      timeAgo: '2h',
      caption: 'Nueva sesión fotográfica en París 📸✨',
    ),
    ModelPost(
      modelName: 'Alex Rivera',
      modelImage: '⭐',
      location: 'New York, USA',
      verified: true,
      likes: 1923,
      comments: 89,
      timeAgo: '5h',
      caption: 'Fashion Week NYC - Día 1 🗽',
    ),
    ModelPost(
      modelName: 'Emma Laurent',
      modelImage: '👑',
      location: 'Milan, Italy',
      verified: false,
      likes: 892,
      comments: 34,
      timeAgo: '8h',
      caption: 'Behind the scenes 🎬',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: CustomScrollView(
        slivers: [
          // Header
          _buildHeader(),
          
          // Stories Section
          _buildStoriesSection(),
          
          // Posts Feed
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildPostCard(_posts[index]),
                childCount: _posts.length,
              ),
            ),
          ),
          
          // Bottom Spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
          color: Color(0xFF18181B),
          border: Border(
            bottom: BorderSide(
              color: Color(0xFF27272A),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Text(
              'Social',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFAFAFA),
              ),
            ),
            const Spacer(),
            ShadButton.ghost(
              icon: const Icon(Icons.search, size: 20),
              onPressed: () {
                // Buscar modelos
              },
            ),
            const SizedBox(width: 8),
            ShadButton.ghost(
              icon: const Icon(Icons.filter_list, size: 20),
              onPressed: () {
                // Filtros
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoriesSection() {
    return SliverToBoxAdapter(
      child: Container(
        height: 120,
        margin: const EdgeInsets.symmetric(vertical: 16),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: 8,
          itemBuilder: (context, index) {
            return _buildStoryItem(index);
          },
        ),
      ),
    );
  }

  Widget _buildStoryItem(int index) {
    final emojis = ['💎', '⭐', '👑', '✨', '🌟', '💫', '🔥', '💝'];
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFFFAFAFA),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF18181B),
            ),
            child: Center(
              child: Text(
                emojis[index],
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            index == 0 ? 'Tu historia' : 'Model ${index + 1}',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFFFAFAFA),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(ModelPost post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF27272A),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF27272A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      post.modelImage,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            post.modelName,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFAFAFA),
                            ),
                          ),
                          if (post.verified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified,
                              size: 14,
                              color: Color(0xFFFAFAFA),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '${post.location} • ${post.timeAgo}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF71717A),
                        ),
                      ),
                    ],
                  ),
                ),
                ShadButton.ghost(
                  icon: const Icon(Icons.more_horiz, size: 20),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          
          // Post Image Placeholder
          Container(
            height: 300,
            color: const Color(0xFF27272A),
            child: const Center(
              child: Icon(
                Icons.photo_outlined,
                size: 64,
                color: Color(0xFF52525B),
              ),
            ),
          ),
          
          // Post Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ShadButton.ghost(
                      icon: const Icon(Icons.favorite_border, size: 20),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 8),
                    ShadButton.ghost(
                      icon: const Icon(Icons.chat_bubble_outline, size: 20),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 8),
                    ShadButton.ghost(
                      icon: const Icon(Icons.share_outlined, size: 20),
                      onPressed: () {},
                    ),
                    const Spacer(),
                    ShadButton.ghost(
                      icon: const Icon(Icons.bookmark_border, size: 20),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${post.likes.toStringAsFixed(0)} likes',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFAFAFA),
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFFFAFAFA),
                    ),
                    children: [
                      TextSpan(
                        text: '${post.modelName} ',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: post.caption),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ver los ${post.comments} comentarios',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF71717A),
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

class ModelPost {
  final String modelName;
  final String modelImage;
  final String location;
  final bool verified;
  final int likes;
  final int comments;
  final String timeAgo;
  final String caption;

  ModelPost({
    required this.modelName,
    required this.modelImage,
    required this.location,
    required this.verified,
    required this.likes,
    required this.comments,
    required this.timeAgo,
    required this.caption,
  });
}
