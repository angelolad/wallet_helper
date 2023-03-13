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
      date_format = "%m-%d-%Y %H:%M"
      date_format_param = "%Y-%m-%d"
      if params[:from_date].empty? || params[:to_date].empty?
        from_date = DateTime.strptime("01-01-2018 00:00", date_format)
        to_date = DateTime.now().strftime(date_format).to_date
        @date_range = "All"
      else
        from_date = DateTime.strptime(params[:from_date], date_format_param)
        to_date = DateTime.strptime(params[:to_date], date_format_param)
        @date_range = "#{from_date.strftime(date_format)} - #{to_date.strftime(date_format)}"
      end

      puts "From date: #{from_date}"
      puts "To date: #{to_date}"
      @address_param = params[:search]

      #Step 2: Using the address get every transaction
      tx_hashes = search_address_transactions[:body].map { |t| t[:tx_hash] }

      #Step 3: Using the tx_hashes see if its a minted or not
      @tx_mints = []
      tx_hashes.each do |tx|
        tx_detail = search_transaction(tx)[:body].slice(:hash, :block_time, :asset_mint_or_burn_count)

        #convert unix time to block time
        tx_detail[:block_time] = Time.at(tx_detail[:block_time]).strftime(date_format)
        date_time = DateTime.strptime(tx_detail[:block_time], date_format)
        if tx_detail[:asset_mint_or_burn_count] > 0 && date_time.to_date.between?(from_date, to_date)
          @tx_mints.push(tx_detail)
        end
      end

      format_mint_transaction

      #Delete any transactions not an nft
      @tx_mints.delete_if { |tx| tx[:asset][0].nil? }

      #puts @tx_mints
    end
  end

  private

  def format_mint_transaction
    @asset_names = []
    @tx_mints.each do |tx|
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
      }.flatten.delete_if { |unit| unit == "lovelace" }

      tx[:asset] = tx[:asset].map { |asset|
        asset_name = search_specific_assets(asset)[:body]
        #If no metadata name is present, transaction minted something other then an nft
        if asset_name[:onchain_metadata].present?
          asset_name[:onchain_metadata]["name"]
        end
      }
    end
  end

  def search_address_transactions
    @blockfrost.get_address_transactions(params[:search], params = { count: 20, order: "desc" })
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
