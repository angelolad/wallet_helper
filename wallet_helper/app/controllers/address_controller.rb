class AddressController < ApplicationController
  require "blockfrost-ruby"

  def index
    @blockfrost = Blockfrostruby::CardanoMainNet.new("mainnetVGTi8Cz1vGmGG4hacNgqQiq2p7amrz0h")

    puts "***************************"
    #stake1uyju2r9mm552rvl4srcru7tv3kkv622yur78yatfgd7qamq6p5rad
    #addr1qx5j4nes9akdpp2u2r4xe3s5hewhpdy07lyfctj82upx4y39c5xthhfg5xeltq8s8eukerdve555fc8uwf6kjsmupmkq8vypuh
    if params[:search].empty?
      redirect_to root_path
    else
      @address_param = params[:search]
      #Step 2: Using the address get every transaction
      tx_hashes = search_address_transactions[:body].map { |t| t[:tx_hash] }

      #Step 3: Using the tx_hashes see if its a minted or not
      @tx_mints = []
      tx_hashes.each do |tx|
        tx_detail = search_transaction(tx)[:body].slice(:hash, :block_time, :asset_mint_or_burn_count)
        if tx_detail[:asset_mint_or_burn_count] > 0
          @tx_mints.push(tx_detail)
        end
      end

      format_mint_transaction

      puts @tx_mints
    end
  end

  private

  def format_mint_transaction
    @asset_names = []
    @tx_mints.each do |tx|
      #convert unix time to block time
      tx[:block_time] = Time.at(tx[:block_time]).strftime("%Y-%m-%d %H:%M:%S")

      #retrieve only the assets minted into the wallet
      outputs = (search_transaction_utxos(tx[:hash])[:body][:outputs].select {
        |assets|
        assets["address"] == @address_param
      })

      #format hash
      tx[:asset] = outputs.map { |amount|
        amount["amount"].map {
          |asset|
          asset["unit"]
        }
      }.flatten.delete_if { |x| x == "lovelace" }

      tx[:asset] = tx[:asset].map { |asset|
        search_specific_assets(asset)[:body][:onchain_metadata]["name"]
      }
    end
  end

  def search_address_transactions
    @blockfrost.get_address_transactions(params[:search], params = { count: 7, order: "desc" })
  end

  def search_transaction(tx)
    @blockfrost.get_transaction(tx)
  end

  def search_specific_assets(asset)
    @blockfrost.get_specific_asset (asset)
  end

  def search_transaction_utxos(tx)
    @blockfrost.get_transaction_utxos(tx)
  end
end
