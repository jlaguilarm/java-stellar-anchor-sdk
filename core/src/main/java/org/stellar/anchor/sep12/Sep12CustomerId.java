package org.stellar.anchor.sep12;

import org.stellar.anchor.event.models.StellarId;

public interface Sep12CustomerId {
  String getId();

  void setId(String id);

  @Deprecated
  String getAccount();

  @Deprecated
  void setAccount(String account);

  String getMemo();

  void setMemo(String memo);

  @Deprecated
  String getMemoType();

  @Deprecated
  void setMemoType(String memoType);

  default StellarId toStellarId() {
    return StellarId.builder()
        .id(getId())
        .account(getAccount())
        .memo(getMemo())
        .memoType(getMemoType())
        .build();
  }
}
