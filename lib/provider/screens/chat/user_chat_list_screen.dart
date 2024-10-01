import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_pagination/firebase_pagination.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:hands_user_app/components/app_widgets.dart';
import 'package:hands_user_app/components/back_widget.dart';
import 'package:hands_user_app/main.dart';
import 'package:hands_user_app/models/user_data.dart';
import 'package:hands_user_app/provider/screens/chat/components/user_item_widget.dart';
import 'package:hands_user_app/provider/utils/constant.dart';
import 'package:nb_utils/nb_utils.dart';

// import '../../auth/sign_in_screen.dart';
import '../../../components/base_scaffold_body.dart';
import '../../../components/empty_error_state_widget.dart';

class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    //
  }

  void loginInFirebase() async {
    appStore.setLoading(true);

    appStore.setUId(
        await authService.signInWithEmailPassword(email: appStore.userEmail));

    appStore.setLoading(false);
    setState(() {});
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget(
        languages.lblChat,
        textColor: white,
        showBack: Navigator.canPop(context),
        textSize: APP_BAR_TEXT_SIZE,
        elevation: 3.0,
        backWidget: BackWidget(),
        color: context.primaryColor,
      ),
      body: Body(
        child: Stack(
          children: [
            SnapHelperWidget(
              future: Future.value(FirebaseAuth.instance.currentUser != null &&
                  appStore.uid.isNotEmpty),
              onSuccess: (isLoggedIn) {
                if (!isLoggedIn) {
                  return NoDataWidget(
                    title: languages.youAreNotConnectedWithChatServer,
                    subTitle:
                        languages.tapBelowButtonToConnectWithOurChatServer,
                    onRetry: () {
                      if (!appStore.isLoggedIn) {
                        // SignInScreen().launch(context);
                      } else {
                        loginInFirebase();
                      }
                    },
                    retryText: languages.connect,
                    imageWidget: EmptyStateWidget(),
                  ).paddingSymmetric(horizontal: 16);
                } else {
                  return FirestorePagination(
                    query:
                        chatServices.fetchChatListQuery(userId: appStore.uid),
                    physics: AlwaysScrollableScrollPhysics(),
                    isLive: true,
                    shrinkWrap: true,
                    itemBuilder: (context, snap, index) {
                      UserData contact = UserData.fromJson(
                          snap.data() as Map<String, dynamic>);
                      return UserItemWidget(userUid: contact.uid.validate());
                    },
                    initialLoader: LoaderWidget(),
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 10),
                    padding:
                        EdgeInsets.only(left: 0, top: 8, right: 0, bottom: 0),
                    limit: PER_PAGE_CHAT_LIST_COUNT,
                    separatorBuilder: (_, i) => Divider(
                        height: 0, indent: 82, color: context.dividerColor),
                    viewType: ViewType.list,
                    onEmpty: NoDataWidget(
                      title: languages.noConversation,
                      subTitle: languages.noConversationSubTitle,
                      imageWidget: EmptyStateWidget(),
                    ).paddingSymmetric(horizontal: 16),
                  );
                }
              },
              loadingWidget: LoaderWidget(),
              errorBuilder: (p0) {
                return NoDataWidget(
                  title: p0,
                  imageWidget: ErrorStateWidget(),
                );
              },
            ),
            Observer(
                builder: (context) =>
                    LoaderWidget().visible(appStore.isLoading)),
          ],
        ),
      ),
    );
  }
}
