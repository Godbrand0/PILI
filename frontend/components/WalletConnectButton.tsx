"use client";

import { ConnectButton } from "@rainbow-me/rainbowkit";
import { useAccount, useSwitchChain } from "wagmi";
import { getChainById, isSupportedChain } from "../config/wagmi";
import { Button } from "./ui/Button";

/**
 * Wallet connection button with network switching support
 */
export function WalletConnectButton() {
  const { address, isConnected, chain } = useAccount();
  const { switchChain } = useSwitchChain();

  // Check if current chain is supported
  const isCurrentChainSupported = chain ? isSupportedChain(chain.id) : false;

  // Handle network switch
  const handleSwitchNetwork = async () => {
    try {
      await switchChain({ chainId: 8008135 }); // Fhenix Helix
    } catch (error) {
      console.error("Failed to switch network:", error);
    }
  };

  if (isConnected && !isCurrentChainSupported) {
    return (
      <div className="flex flex-col gap-2">
        <div className="flex items-center gap-2 p-3 bg-yellow-50 border border-yellow-200 rounded-lg">
          <div className="w-4 h-4 rounded-full bg-yellow-600" />
          <span className="text-sm text-yellow-800">
            Unsupported network. Please switch to Fhenix Helix.
          </span>
        </div>
        <Button onClick={handleSwitchNetwork} variant="outline">
          Switch to Fhenix Helix
        </Button>
      </div>
    );
  }

  return (
    <ConnectButton.Custom>
      {({
        account,
        chain,
        openAccountModal,
        openChainModal,
        openConnectModal,
        authenticationStatus,
        mounted,
      }) => {
        // Note: If your app doesn't use authentication, you
        // can remove the 'authenticationStatus' check
        const ready = mounted && authenticationStatus !== "loading";
        const connected =
          ready &&
          account &&
          chain &&
          (!authenticationStatus || authenticationStatus === "authenticated");

        return (
          <div
            {...(!ready && {
              "aria-hidden": true,
              style: {
                opacity: 0,
                pointerEvents: "none",
                userSelect: "none",
              },
            })}
          >
            {(() => {
              if (!connected) {
                return (
                  <Button onClick={openConnectModal} className="w-full">
                    Connect Wallet
                  </Button>
                );
              }

              if (chain.unsupported) {
                return (
                  <Button
                    onClick={openChainModal}
                    variant="outline"
                    className="w-full"
                  >
                    Wrong network
                  </Button>
                );
              }

              return (
                <div style={{ display: "flex", gap: 12 }}>
                  <Button
                    onClick={openChainModal}
                    variant="outline"
                    className="flex items-center gap-2"
                  >
                    {chain.hasIcon && (
                      <div
                        style={{
                          background: chain.iconBackground,
                          width: 12,
                          height: 12,
                          borderRadius: 999,
                          overflow: "hidden",
                          marginRight: 4,
                        }}
                      >
                        {chain.iconUrl && (
                          <img
                            alt={chain.name ?? "Chain icon"}
                            src={chain.iconUrl}
                            style={{ width: 12, height: 12 }}
                          />
                        )}
                      </div>
                    )}
                    {chain.name}
                  </Button>

                  <Button onClick={openAccountModal} variant="outline">
                    {account.displayName}
                    {account.displayBalance
                      ? ` (${account.displayBalance})`
                      : ""}
                  </Button>
                </div>
              );
            })()}
          </div>
        );
      }}
    </ConnectButton.Custom>
  );
}
