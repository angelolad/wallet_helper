require "blockfrost-ruby"

class HomeController < ApplicationController
  def index
    @blockfrost = Blockfrostruby::CardanoMainNet.new("mainnetVGTi8Cz1vGmGG4hacNgqQiq2p7amrz0h")
    puts "***************************"
    #stake1uyju2r9mm552rvl4srcru7tv3kkv622yur78yatfgd7qamq6p5rad
    #addr1qx5j4nes9akdpp2u2r4xe3s5hewhpdy07lyfctj82upx4y39c5xthhfg5xeltq8s8eukerdve555fc8uwf6kjsmupmkq8vypuh
    #Step 2: Using the addresses get every transaction
    transactions = @blockfrost.get_address_transactions("addr1qx5j4nes9akdpp2u2r4xe3s5hewhpdy07lyfctj82upx4y39c5xthhfg5xeltq8s8eukerdve555fc8uwf6kjsmupmkq8vypuh", params = { count: 5, order: "desc" })
    #Step 3: Get only the transactions ids
    tx_hashes = transactions[:body].map { |t| t[:tx_hash] }

    #Step 4: Using the tx_hashes see if its a minted or not
    tx_mints = []
    tx_hashes.each do |tx|
      tx_detail = (@blockfrost.get_transaction(tx))

      if tx_detail[:body][:asset_mint_or_burn_count] > 0
        tx_mints.push(tx_detail)
      end
    end

    #puts tx_mints
    #Step 5: Get asset names and policy id
    assets = []
    tx_mints.each do |tx|
      tx[:body][:output_amount].each do |a|
        next if a["unit"].include?("lovelace")
        assets.push(a["unit"])
      end
    end

    asset_details = []
    assets.each do |a|
      asset_details.push({ a[0..56] => a[56..94] })
      #asset_detail = (@blockfrost.)
    end
    puts asset_details.class
  end
end
