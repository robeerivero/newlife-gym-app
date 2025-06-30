import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/chatbot_viewmodel.dart';

class ChatBotScreen extends StatefulWidget {
  final String section;

  const ChatBotScreen({Key? key, required this.section}) : super(key: key);

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatBotViewModel(widget.section),
      child: Consumer<ChatBotViewModel>(
        builder: (context, vm, child) {
          final isDesktop = MediaQuery.of(context).size.width > 600;

          return Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: AppBar(
              title: Text(
                'Asistente de ${widget.section}',
                style: TextStyle(fontSize: isDesktop ? 18 : 18.sp),
              ),
              backgroundColor: const Color(0xFF42A5F5),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(16.w),
                      itemCount: vm.chatHistory.length,
                      itemBuilder: (context, index) {
                        final message = vm.chatHistory[index];
                        return _buildChatBubble(
                          message['text'],
                          timestamp: message['timestamp'],
                          isBot: message['isBot'],
                          isDesktop: isDesktop,
                        );
                      },
                    ),
                  ),
                  _buildInputField(vm, isDesktop),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatBubble(
    String text, {
    required DateTime timestamp,
    required bool isBot,
    required bool isDesktop,
  }) {
    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isBot ? Colors.grey[300] : const Color(0xFF42A5F5),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isBot ? Radius.zero : const Radius.circular(16),
            bottomRight: isBot ? const Radius.circular(16) : Radius.zero,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isBot ? Colors.black : Colors.white,
                fontSize: isDesktop ? 16 : 16.sp,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              DateFormat('HH:mm').format(timestamp),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: isDesktop ? 12 : 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(ChatBotViewModel vm, bool isDesktop) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: vm.questionController,
              decoration: InputDecoration(
                hintText: 'Escribe tu pregunta...',
                hintStyle: TextStyle(fontSize: isDesktop ? 14 : 14.sp),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20.w,
                  vertical: 14.h,
                ),
              ),
              style: TextStyle(fontSize: isDesktop ? 14 : 14.sp),
              onSubmitted: (_) {
                if (vm.questionController.text.trim().isNotEmpty) {
                  vm.handleUserQuestion(() {
                    setState(() {});
                    _scrollToBottom();
                  });
                }
              },
            ),
          ),
          SizedBox(width: 10.w),
          IconButton(
            icon: const Icon(Icons.send, color: Color(0xFF42A5F5)),
            onPressed: () {
              if (vm.questionController.text.trim().isNotEmpty) {
                vm.handleUserQuestion(() {
                  setState(() {});
                  _scrollToBottom();
                });
              }
            },
          ),
        ],
      ),
    );
  }
}
