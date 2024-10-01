import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:hands_user_app/provider/utils/extensions/context_ext.dart';
import 'package:hands_user_app/provider/utils/colors.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../components/app_widgets.dart';
import '../../../../components/cached_image_widget.dart';
import '../../../../components/empty_error_state_widget.dart';
import '../../../../main.dart';
import '../../../../models/booking_detail_response.dart';
import '../../../../models/service_model.dart';
import '../../../../provider/networks/rest_apis.dart';
import '../../../../provider/utils/common.dart';
import '../../../../provider/utils/configs.dart';
import '../../../../provider/utils/constant.dart';

class SelectAddonServiceComponent extends StatefulWidget {
  final bool isUpdate;
  final ServiceAddon? serviceAddonData;
  final int? selectedServiceId;

  SelectAddonServiceComponent(
      {this.isUpdate = false, this.serviceAddonData, this.selectedServiceId});

  @override
  _SelectAddonServiceComponentState createState() =>
      _SelectAddonServiceComponentState();
}

class _SelectAddonServiceComponentState
    extends State<SelectAddonServiceComponent> {
  ScrollController scrollController = ScrollController();

  TextEditingController searchCont = TextEditingController();

  List<ServiceData> serviceList = [];

  bool isLastPage = false;

  int page = 1;
  int selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    if (widget.isUpdate) {
      log('widget.isUpdate=== ${widget.isUpdate}');
      log('widget.serviceAddonData!.serviceId.validate()=== ${widget.serviceAddonData!.serviceId.validate()}');
      if (widget.selectedServiceId != null) {
        appStorePro.selectedServiceData.id = widget.selectedServiceId;
      } else {
        appStorePro.selectedServiceData.id =
            widget.serviceAddonData!.serviceId.validate();
      }
    }

    await fetchAllServices(searchText: '');
  }

  //region Get Services List
  Future<void> fetchAllServices({String? searchText = ""}) async {
    appStorePro.setLoading(true);

    await getServicesList(page,
            search: searchText, providerId: appStorePro.userId)
        .then((value) {
      if (page == 1) serviceList.clear();

      isLastPage = value.data!.length != PER_PAGE_ITEM;

      serviceList.addAll(value.data!);

      if (appStorePro.selectedServiceData.id != null) {
        serviceList.forEach((e2) {
          if (e2.id == appStorePro.selectedServiceData.id) {
            e2.isSelected = true;
          }
        });
        /*appStorePro.selectedServiceList.validate().forEach((e1) {
          serviceList.forEach((e2) {
            if (e2.id == e1.id) {
              e2.isSelected = true;
            }
          });
        });*/
      }

      appStorePro.setLoading(false);

      setState(() {});
    }).catchError((e) {
      appStorePro.setLoading(false);

      toast(e.toString());
    });
  }

  //endregion

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: appBarWidget(
          languages.selectService,
          textColor: white,
          color: context.primaryColor,
        ),
        body: Stack(
          children: [
            AnimatedScrollView(
              controller: scrollController,
              listAnimationType: ListAnimationType.FadeIn,
              fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
              crossAxisAlignment: CrossAxisAlignment.start,
              physics: AlwaysScrollableScrollPhysics(),
              onSwipeRefresh: () async {
                page = 1;

                init();
                setState(() {});

                return await 2.seconds.delay;
              },
              onNextPage: () {
                if (!isLastPage) {
                  page++;
                  fetchAllServices();
                  setState(() {});
                }
              },
              children: [
                24.height,
                // Search Service TextField
                AppTextField(
                  controller: searchCont,
                  textFieldType: TextFieldType.NAME,
                  decoration:
                      inputDecoration(context, hint: languages.lblSearchHere),
                  onFieldSubmitted: (s) {
                    appStorePro.setLoading(true);

                    fetchAllServices(searchText: s);
                  },
                ).paddingSymmetric(horizontal: 16),
                24.height,
                // Service List Section
                Text(languages.lblServices,
                        style: boldTextStyle(size: LABEL_TEXT_SIZE))
                    .paddingSymmetric(horizontal: 16),
                8.height,
                if (serviceList.isNotEmpty)
                  AnimatedListView(
                    itemCount: serviceList.length,
                    shrinkWrap: true,
                    padding: EdgeInsets.only(left: 8, right: 8, bottom: 70),
                    disposeScrollController: false,
                    physics: NeverScrollableScrollPhysics(),
                    itemBuilder: (ctx, i) {
                      ServiceData data = serviceList[i];
                      bool isSelected = data.isSelected.validate();

                      return Container(
                        width: context.width(),
                        margin: EdgeInsets.all(8),
                        padding: EdgeInsets.all(8),
                        decoration: boxDecorationRoundedWithShadow(
                            defaultRadius.toInt(),
                            backgroundColor: context.cardColor),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CachedImageWidget(
                                  url: data.imageAttachments!.isNotEmpty
                                      ? data.imageAttachments!.first.validate()
                                      : "",
                                  height: 50,
                                  fit: BoxFit.cover,
                                  radius: defaultRadius,
                                ),
                                16.width,
                                Text(data.name.validate(),
                                        style: secondaryTextStyle(
                                            color: context.iconColor))
                                    .expand(),
                              ],
                            ).expand(),
                            16.width,
                            Icon(
                              ((appStorePro.selectedServiceData.id ==
                                          data.id) ||
                                      selectedIndex == i)
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              size: 28,
                              color: ((appStorePro.selectedServiceData.id ==
                                          data.id) ||
                                      selectedIndex == i)
                                  ? primaryColor
                                  : context.iconColor,
                            ),
                            8.width,
                          ],
                        ).onTap(() {
                          /*if (data.isSelected.validate()) {
                          selectedIndex = -1;
                        } else {
                          selectedIndex = i;
                          appStorePro.setSelectedServiceData(data);
                        }*/

                          data.isSelected = !data.isSelected.validate();
                          selectedIndex = i;
                          appStorePro.setSelectedServiceData(data);
                          log('Service id: ${appStorePro.selectedServiceData.id}');
                          log('Service Name: ${appStorePro.selectedServiceData.name}');

                          setState(() {});
                        }),
                      );
                    },
                    onNextPage: () {
                      if (!isLastPage) {
                        page++;
                        fetchAllServices();
                        setState(() {});
                      }
                    },
                  )
                else
                  Observer(
                    builder: (context) {
                      return NoDataWidget(
                        imageWidget: EmptyStateWidget(),
                        title: context.translate.noServiceFound,
                        imageSize: Size(150, 150),
                        subTitle: "",
                      ).visible(
                          (!appStorePro.isLoading && serviceList.isEmpty));
                    },
                  ),
              ],
            ),
            Observer(
                builder: (context) =>
                    LoaderWidget().visible(appStorePro.isLoading)),
          ],
        ),
        floatingActionButton: appStorePro.selectedServiceData.id != null
            ? FloatingActionButton(
                child: Icon(Icons.check, color: Colors.white),
                backgroundColor: context.primaryColor,
                onPressed: () {
                  finish(context, appStorePro.selectedServiceData.id);
                },
              )
            : Offstage());
  }
}
