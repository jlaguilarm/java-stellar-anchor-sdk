package org.stellar.anchor.platform.action;

import static org.stellar.anchor.api.platform.PlatformTransactionData.Kind.WITHDRAWAL;
import static org.stellar.anchor.api.rpc.action.ActionMethod.NOTIFY_OFFCHAIN_FUNDS_AVAILABLE;
import static org.stellar.anchor.api.sep.SepTransactionStatus.PENDING_ANCHOR;
import static org.stellar.anchor.api.sep.SepTransactionStatus.PENDING_USR_TRANSFER_COMPLETE;

import java.util.Set;
import javax.validation.Validator;
import org.stellar.anchor.api.exception.rpc.InvalidRequestException;
import org.stellar.anchor.api.platform.PlatformTransactionData.Kind;
import org.stellar.anchor.api.rpc.action.ActionMethod;
import org.stellar.anchor.api.rpc.action.NotifyOffchainFundsAvailableRequest;
import org.stellar.anchor.api.sep.SepTransactionStatus;
import org.stellar.anchor.asset.AssetService;
import org.stellar.anchor.horizon.Horizon;
import org.stellar.anchor.platform.data.JdbcSep24Transaction;
import org.stellar.anchor.platform.data.JdbcSepTransaction;
import org.stellar.anchor.sep24.Sep24TransactionStore;
import org.stellar.anchor.sep31.Sep31TransactionStore;

public class NotifyOffchainFundsAvailableHandler
    extends ActionHandler<NotifyOffchainFundsAvailableRequest> {

  public NotifyOffchainFundsAvailableHandler(
      Sep24TransactionStore txn24Store,
      Sep31TransactionStore txn31Store,
      Validator validator,
      Horizon horizon,
      AssetService assetService) {
    super(
        txn24Store,
        txn31Store,
        validator,
        horizon,
        assetService,
        NotifyOffchainFundsAvailableRequest.class);
  }

  @Override
  public ActionMethod getActionType() {
    return NOTIFY_OFFCHAIN_FUNDS_AVAILABLE;
  }

  @Override
  protected SepTransactionStatus getNextStatus(
      JdbcSepTransaction txn, NotifyOffchainFundsAvailableRequest request)
      throws InvalidRequestException {
    return PENDING_USR_TRANSFER_COMPLETE;
  }

  @Override
  protected Set<SepTransactionStatus> getSupportedStatuses(JdbcSepTransaction txn) {
    JdbcSep24Transaction txn24 = (JdbcSep24Transaction) txn;
    if (WITHDRAWAL == Kind.from(txn24.getKind())) {
      if (txn24.getTransferReceivedAt() != null) {
        return Set.of(PENDING_ANCHOR);
      }
    }
    return Set.of();
  }

  @Override
  protected Set<String> getSupportedProtocols() {
    return Set.of("24");
  }

  @Override
  protected void updateTransactionWithAction(
      JdbcSepTransaction txn, NotifyOffchainFundsAvailableRequest request) {
    if (request.getExternalTransactionId() != null) {
      txn.setExternalTransactionId(request.getExternalTransactionId());
    }
  }
}
