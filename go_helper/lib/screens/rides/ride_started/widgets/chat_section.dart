import 'package:flutter/material.dart';
import 'package:go_helper/utils/constants/colors.dart';
import 'package:go_helper/model/chat_message.dart';

class ChatSection extends StatelessWidget {
  final TextEditingController messageController;
  final List<ChatMessage> chatMessages;
  final Function(String) onSendMessage;
  final double screenWidth;

  const ChatSection({
    super.key,
    required this.messageController,
    required this.chatMessages,
    required this.onSendMessage,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chat with Driver',
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.bold,
            color: HColors.primary,
          ),
        ),
        SizedBox(height: screenWidth * 0.03),
        if (chatMessages.isNotEmpty)
          SizedBox(
            height: screenWidth * 0.4,
            child: ListView.builder(
              padding: EdgeInsets.only(bottom: screenWidth * 0.02),
              itemCount: chatMessages.length,
              itemBuilder:
                  (context, index) => _buildChatMessage(chatMessages[index]),
            ),
          )
        else
          SizedBox(height: screenWidth * 0.02),
        _buildChatInput(),
      ],
    );
  }

  Widget _buildChatMessage(ChatMessage message) {
    return Align(
      alignment:
          message.isDriver ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.only(bottom: screenWidth * 0.02),
        padding: EdgeInsets.all(screenWidth * 0.03),
        constraints: BoxConstraints(maxWidth: screenWidth * 0.7),
        decoration: BoxDecoration(
          color:
              message.isDriver
                  ? HColors.primary.withOpacity(0.1)
                  : HColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          border: Border.all(
            color: HColors.primary.withOpacity(0.15),
            width: 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                fontSize: screenWidth * 0.033,
                color: HColors.primary,
              ),
            ),
            SizedBox(height: screenWidth * 0.005),
            Text(
              message.time,
              style: TextStyle(
                fontSize: screenWidth * 0.025,
                color: HColors.primary.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      height: screenWidth * 0.12,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.06),
        boxShadow: [
          BoxShadow(
            color: HColors.primary.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: HColors.primary.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.only(left: screenWidth * 0.04),
            child: Icon(
              Icons.message,
              color: HColors.primary,
              size: screenWidth * 0.05,
            ),
          ),
          SizedBox(width: screenWidth * 0.02),
          Expanded(
            child: TextField(
              controller: messageController,
              decoration: InputDecoration(
                hintText: 'Type here...',
                hintStyle: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: HColors.primary.withOpacity(0.5),
                  fontStyle: FontStyle.italic,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.03,
                ),
              ),
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                color: HColors.primary,
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: screenWidth * 0.02),
            width: screenWidth * 0.09,
            height: screenWidth * 0.09,
            decoration: const BoxDecoration(
              color: HColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () {
                if (messageController.text.isNotEmpty) {
                  onSendMessage(messageController.text);
                  messageController.clear();
                }
              },
              icon: Icon(
                Icons.send,
                color: Colors.white,
                size: screenWidth * 0.04,
              ),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
