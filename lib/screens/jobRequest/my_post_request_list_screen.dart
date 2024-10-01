import 'dart:convert';

import 'package:hands_user_app/component/loader_widget.dart';
import 'package:hands_user_app/main.dart';
import 'package:hands_user_app/model/get_my_post_job_list_response.dart';
import 'package:hands_user_app/network/network_utils.dart';
import 'package:hands_user_app/network/rest_apis.dart';
import 'package:hands_user_app/screens/jobRequest/components/my_post_request_item_component.dart';
import 'package:hands_user_app/screens/jobRequest/create_post_request_screen.dart';
import 'package:hands_user_app/screens/jobRequest/shimmer/my_post_job_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../component/base_scaffold_widget.dart';
import '../../component/empty_error_state_widget.dart';

class MyPostRequestListScreen extends StatefulWidget {
  @override
  _MyPostRequestListScreenState createState() =>
      _MyPostRequestListScreenState();
}

class _MyPostRequestListScreenState extends State<MyPostRequestListScreen> {
  late Future<List<PostJobData>> future;
  List<PostJobData> postJobList = [];

  int page = 1;
  bool isLastPage = false;
  bool isApiCalled = false;

  @override
  void initState() {
    super.initState();
    init();
    getLocation();
  }

  Future<void> init() async {
    future =
        getPostJobList(page, postJobList: postJobList, lastPageCallBack: (val) {
      isLastPage = val;
    });
  }

  void getLocation() {
    Geolocator.requestPermission().then((value) {
      if (value == LocationPermission.whileInUse ||
          value == LocationPermission.always) {
        Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
            .then((value) {
          appStore.setLatitude(value.latitude);
          appStore.setLongitude(value.longitude);
          setState(() {});
        }).catchError(onError);
      }
    });
  }

  @override
  void dispose() {
    setStatusBarColor(Colors.transparent,
        statusBarIconBrightness: Brightness.light);
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: "My Booking",
      child: Stack(
        children: [
          SnapHelperWidget<List<PostJobData>>(
            future: future,
            initialData: cachedPostJobList,
            onSuccess: (data) {
              return AnimatedListView(
                itemCount: data.length,
                physics: BouncingScrollPhysics(),
                shrinkWrap: true,
                padding: EdgeInsets.only(top: 12, bottom: 70),
                listAnimationType: ListAnimationType.FadeIn,
                fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                itemBuilder: (_, i) {
                  PostJobData postJob = data[i];

                  return MyPostRequestItemComponent(
                    data: postJob,
                    callback: (v) {
                      appStore.setLoading(v);

                      if (v) {
                        page = 1;
                        init();
                        setState(() {});
                      }
                    },
                  );
                },
                emptyWidget: NoDataWidget(
                  title: language.noPostJobFound,
                  subTitle: language.noPostJobFoundSubtitle,
                  imageWidget: EmptyStateWidget(),
                ),
                onNextPage: () {
                  if (!isLastPage) {
                    page++;
                    appStore.setLoading(true);

                    init();
                    setState(() {});
                  }
                },
                onSwipeRefresh: () async {
                  page = 1;

                  init();
                  setState(() {});

                  return await 2.seconds.delay;
                },
              );
            },
            loadingWidget: MyPostJobShimmer(),
            errorBuilder: (error) {
              return NoDataWidget(
                title: error,
                imageWidget: ErrorStateWidget(),
                retryText: language.reload,
                onRetry: () {
                  page = 1;
                  appStore.setLoading(true);

                  init();
                  setState(() {});
                },
              );
            },
          ),
          Observer(
              builder: (context) => LoaderWidget().visible(appStore.isLoading))
        ],
      ),
      // bottomNavigationBar: AppButton(
      //   child: Text(language.requestNewJob, style: boldTextStyle(color: white)),
      //   color: context.primaryColor,
      //   width: context.width(),
      //   onTap: () async {
      //     bool? res = await CreatePostRequestScreen().launch(context);

      //     if (res ?? false) {
      //       page = 1;
      //       init();
      //       setState(() {});
      //     }
      //   },
      // ).paddingAll(16),
    );
  }
}
