# Live Features Enhancement TODO

Current Task: Add gift gallery for viewers, fix chat, guest ad popup.

## Steps (in order):

1. [ ] ✅ Create TODO.md (done)
2. [✅] Create `lib/widgets/gift_picker.dart` (GiftPickerGrid widget)
3. [✅] Update `lib/screens/live_screen.dart`: Pass `isBroadcaster: user.id == stream['hostId'] ?? false` in join args
4. [✅] Update `lib/screens/live_broadcast_screen.dart`:
   - Add TextEditingController _chatController;
   - Fix chat send: _sendChatMessage() with realtime.sendChatMessage
   - Viewer mode: Replace camera with placeholder video/black bg if !isBroadcaster
   - Add FAB for gifts if viewer
   - Guest ad: if(user==null) Timer(Duration(seconds:30), showAdDialog())
5. [ ] Test chat/gifts/ad
6. [ ] attempt_completion

Next: Step 2
