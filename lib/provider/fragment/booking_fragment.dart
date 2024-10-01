import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:hands_user_app/components/app_widgets.dart';
import 'package:hands_user_app/components/booking_item_component.dart';
import 'package:hands_user_app/provider/fragment/shimmer/booking_shimmer.dart';
import 'package:hands_user_app/main.dart';
import 'package:hands_user_app/models/booking_list_response.dart';
import 'package:hands_user_app/provider/networks/rest_apis.dart';
import 'package:hands_user_app/provider/utils/constant.dart';
import 'package:hands_user_app/provider/utils/extensions/string_extension.dart';
import 'package:hands_user_app/provider/utils/model_keys.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../components/booking_status_filter_bottom_sheet.dart';
import '../../components/cached_image_widget.dart';
import '../../components/empty_error_state_widget.dart';
import '../utils/common.dart';
import '../utils/images.dart';

// ignore: must_be_immutable new screen
class BookingFragment extends StatefulWidget {
  String? statusType;
  final int? bookingId;

  BookingFragment({this.statusType, this.bookingId});

  @override
  BookingFragmentState createState() => BookingFragmentState();
}

class BookingFragmentState extends State<BookingFragment>
    with SingleTickerProviderStateMixin {
  ScrollController scrollController = ScrollController();

  int page = 1;
  List<BookingDatas> bookings = [];

  String selectedValue = BOOKING_PAYMENT_STATUS_ALL;
  bool isLastPage = false;
  bool hasError = false;
  bool isApiCalled = false;

  Future<List<BookingDatas>>? future;
  UniqueKey keyForList = UniqueKey();

  FocusNode myFocusNode = FocusNode();

  TextEditingController searchCont = TextEditingController();

  @override
  void initState() {
    super.initState();
    init();
    LiveStream().on(LIVESTREAM_HANDY_BOARD, (index) {
      if (index is Map && index["index"] == 1) {
        selectedValue = BookingStatusKeys.accept;
        init();
        setState(() {});
      }
    });

    LiveStream().on(LIVESTREAM_HANDYMAN_ALL_BOOKING, (index) {
      if (index == 1) {
        selectedValue = '';
        init();
        setState(() {});
      }
    });

    LiveStream().on(LIVESTREAM_UPDATE_BOOKINGS, (p0) {
      appStore.setLoading(true);
      page = 1;
      init();
      setState(() {});
    });

    LiveStream().on(LIVESTREAM_UPDATE_BOOKING_LIST, (p0) {
      appStore.setLoading(true);
      page = 1;
      init();
      setState(() {});
    });

    cachedBookingStatusDropdown.validate().forEach((element) {
      element.isSelected = false;
    });
  }

  void init({String status = ''}) async {
    future = getBookingList(page,
        status: status,
        searchText: searchCont.text,
        bookings: bookings, lastPageCallback: (b) {
      isLastPage = b;
    });
    appStore.setLoading(false);
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    LiveStream().dispose(LIVESTREAM_UPDATE_BOOKINGS);
    LiveStream().dispose(LIVESTREAM_HANDY_BOARD);
    // LiveStream().dispose(LIVESTREAM_HANDYMAN_ALL_BOOKING);
    // LiveStream().dispose(LIVESTREAM_HANDY_BOARD);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget(
        languages.lblBooking,
        textColor: white,
        color: context.primaryColor,
      ),
      body: Stack(
        children: [
          SnapHelperWidget<List<BookingDatas>>(
            //initialData: cachedBookingList,
            future: future,
            loadingWidget: BookingShimmer(),
            onSuccess: (list) {
              return AnimatedScrollView(
                controller: scrollController,
                listAnimationType: ListAnimationType.FadeIn,
                fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                onSwipeRefresh: () async {
                  page = 1;
                  appStore.setLoading(true);

                  init(status: selectedValue);
                  setState(() {});

                  return await 1.seconds.delay;
                },
                onNextPage: () {
                  if (!isLastPage) {
                    page++;
                    appStore.setLoading(true);

                    init();
                    setState(() {});
                  }
                },
                children: [
                  SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                        left: 16, right: 16, top: 24, bottom: 8),
                    child: Row(
                      children: [
                        AppTextField(
                          textFieldType: TextFieldType.OTHER,
                          focus: myFocusNode,
                          controller: searchCont,
                          suffix: CloseButton(
                            onPressed: () {
                              page = 1;
                              searchCont.clear();

                              appStore.setLoading(true);

                              init();
                              setState(() {});
                            },
                          ).visible(searchCont.text.isNotEmpty),
                          onFieldSubmitted: (s) {
                            page = 1;

                            appStore.setLoading(true);

                            init();
                            setState(() {});
                          },
                          decoration: inputDecoration(context).copyWith(
                            hintText: appStore.selectedLanguageCode == 'en'
                                ? "Search for booking"
                                : "إبحث في الطلبات",
                            prefixIcon:
                                ic_search.iconImage(size: 8).paddingAll(16),
                            hintStyle: secondaryTextStyle(),
                          ),
                        ).expand(),
                        16.width,
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration:
                              boxDecorationDefault(color: context.primaryColor),
                          child: CachedImageWidget(
                            url: ic_filter,
                            height: 26,
                            width: 26,
                            color: Colors.white,
                          ),
                        ).onTap(
                          () async {
                            hideKeyboard(context);
                            String? res = await showModalBottomSheet(
                              backgroundColor: Colors.transparent,
                              context: context,
                              isScrollControlled: true,
                              isDismissible: true,
                              shape: RoundedRectangleBorder(
                                  borderRadius: radiusOnly(
                                      topLeft: defaultRadius,
                                      topRight: defaultRadius)),
                              builder: (_) {
                                return BookingStatusFilterBottomSheet();
                              },
                            );

                            if (res.validate().isNotEmpty) {
                              page = 1;
                              appStore.setLoading(true);

                              selectedValue = res!;
                              init(status: res);

                              if (bookings.isNotEmpty) {
                                scrollController.animateTo(0,
                                    duration: 1.seconds,
                                    curve: Curves.easeOutQuart);
                              } else {
                                scrollController = ScrollController();
                                keyForList = UniqueKey();
                              }
                              setState(() {});
                            }
                          },
                          borderRadius: radius(),
                        ),
                      ],
                    ),
                  ),
                  AnimatedListView(
                    key: keyForList,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    listAnimationType: ListAnimationType.FadeIn,
                    fadeInConfiguration:
                        FadeInConfiguration(duration: 2.seconds),
                    itemCount: list.length,
                    shrinkWrap: true,
                    disposeScrollController: true,
                    physics: NeverScrollableScrollPhysics(),
                    emptyWidget: SizedBox(
                      width: context.width(),
                      height: context.height() * 0.55,
                      child: NoDataWidget(
                        title: languages.noBookingTitle,
                        subTitle: languages.noBookingSubTitle,
                        imageWidget: EmptyStateWidget(),
                      ),
                    ),
                    itemBuilder: (_, index) => BookingItemComponent(
                        bookingData: list[index], index: index),
                  ),
                ],
              );
            },
            errorBuilder: (error) {
              return NoDataWidget(
                title: error,
                retryText: languages.reload,
                imageWidget: ErrorStateWidget(),
                onRetry: () {
                  page = 1;
                  appStore.setLoading(true);

                  init();
                  setState(() {});
                },
              );
            },
          ),
          Observer(builder: (_) => LoaderWidget().visible(appStore.isLoading)),
        ],
      ),
    );
  }
}
